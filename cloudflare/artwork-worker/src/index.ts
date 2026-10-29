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

export default {
	async fetch(request, env, ctx): Promise<Response> {
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

			//detect file size
			const data = await request.arrayBuffer();
			if (data.byteLength > MAX_BYTES) {
				return new Response("Maximum image size is 25MB", { status: 413 });
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
} satisfies ExportedHandler<Env>;