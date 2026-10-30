/**
 * PickAFrame artwork worker.
 *
 * PUT /v1/drafts/{draftId}/artwork  — upload a PNG (Firebase token required)
 * GET /v1/drafts/{draftId}/artwork  — read it back (owner only)
 *
 * Objects are stored in R2 at drafts/{uid}/{draftId}/artwork.png,
 * where uid comes from the verified Firebase ID token.
 */

import { createRemoteJWKSet, jwtVerify } from "jose";

const GOOGLE_KEYS = createRemoteJWKSet(
	new URL("https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com")
);

//set the maximum size of the image, 25mb maximum
const MAX_BYTES = 25 * 1024 * 1024;

//cache
const NO_STORE = "private, no-store";

// Every PNG file starts with these 8 bytes.
const PNG_SIGNATURE = [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];

// Sent on every response: no MIME sniffing, no framing, no referrer leaks.
const SECURITY_HEADERS = {
	"X-Content-Type-Options": "nosniff",
	"X-Frame-Options": "DENY",
	"Referrer-Policy": "no-referrer",
};

// Lets the Flutter web app call the Worker from any origin (flutter run picks
// a random localhost port). "*" is safe here: access is granted by the Bearer
// token, never by cookies.
const CORS_HEADERS = {
	"Access-Control-Allow-Origin": "*",
	"Access-Control-Allow-Methods": "GET, PUT, OPTIONS",
	"Access-Control-Allow-Headers": "Authorization, Content-Type",
	"Access-Control-Max-Age": "86400",
};

function isPng(data: ArrayBuffer): boolean {
	const bytes = new Uint8Array(data, 0, Math.min(8, data.byteLength));
	return bytes.length === 8 && PNG_SIGNATURE.every((b, i) => bytes[i] === b);
}

export default {
	async fetch(request, env, ctx): Promise<Response> {
		// Browsers send a token-less OPTIONS preflight before each PUT/GET with
		// an Authorization header; answer it before the token check.
		const response = request.method === "OPTIONS"
			? new Response(null, { status: 204 })
			: await handle(request, env);
		for (const [name, value] of Object.entries({ ...SECURITY_HEADERS, ...CORS_HEADERS })) {
			response.headers.set(name, value);
		}
		return response;
	}
} satisfies ExportedHandler<Env>;

async function handle(request: Request, env: Env): Promise<Response> {
		const url = new URL(request.url);
		//split the pathname
		const parts = url.pathname.split("/");
		//check token
		const auth = request.headers.get("Authorization");
		if (!auth || !auth.startsWith("Bearer ")) {
			return new Response("Unauthorized", { status: 401 });
		}

		const token = auth.slice(7);
		if (token === "") {
			return new Response("Unauthorized", { status: 401 })
		}

		let uid;
		try {
			const { payload } = await jwtVerify(token, GOOGLE_KEYS, {
				issuer: "https://securetoken.google.com/" + env.FIREBASE_PROJECT_ID,
				audience: env.FIREBASE_PROJECT_ID,
				algorithms: ["RS256"],

			});
			uid = payload.sub;

		} catch {
			return new Response("Unauthorized", { status: 401 });
		}

		if (!uid) {
			return new Response("Unauthorized", { status: 401 });
		}

		const draftId = parts[3];
		const asset = parts[4];
		const isDraftRoute = parts.length === 5 && 
							 parts[1] === "v1" &&
							 parts[2] === "drafts" &&
							 draftId &&
							 asset === "artwork";
		
		const key = "drafts/" + uid + "/" + draftId + "/" + asset + ".png"					 

		if (request.method === "PUT" && isDraftRoute) {
			const type = request.headers.get("Content-Type");
			//help detect file type
			if (type !== "image/png") {
				return new Response("Only PNG allowed", { status: 415 })
			}

			//detect file size: refuse a declared oversize upload before reading it,
			//then check the bytes actually received
			const declared = Number(request.headers.get("Content-Length") ?? "0");
			if (declared > MAX_BYTES) {
				return new Response("Maximum image size is 25MB", { status: 413 });
			}
			const data = await request.arrayBuffer();
			if (data.byteLength > MAX_BYTES) {
				return new Response("Maximum image size is 25MB", { status: 413 });
			}
			if (!isPng(data)) {
				return new Response("Only PNG allowed", { status: 415 });
			}

			await env.ARTWORKS.put(key, data);
			return Response.json({ url: "/v1/drafts/" + draftId + "/" + asset },
								 { headers: {"Cache-Control": NO_STORE}}
			);
		}

		if (request.method === "GET" && isDraftRoute) {
			const obj = await env.ARTWORKS.get(key);

			if (obj === null) {
				return new Response("Not Found", { status: 404 });
			}

			return new Response(obj.body, {
				headers: { "Content-Type": "image/png",
						   "Cache-Control": NO_STORE,
				 }
			});
		}
		return new Response("Not Found", {status: 404});
}