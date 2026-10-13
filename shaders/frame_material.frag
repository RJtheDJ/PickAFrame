// Per-pixel lighting for the four mitred rails of a frame.
//
// Each pixel finds which rail it is on (the nearest outer edge; the mitres are
// where two are equally near), its position across the moulding profile, and
// its surface normal: the profile's slope (from a lookup texture) plus fine
// detail from the material's normal map. It is then lit by one directional
// light. Metals reflect a simple studio instead of being lit like paint.
//
// Photographed mouldings ("strip mode") already show their carving and its
// lighting, so instead the photo is relit: brightened or darkened by how much
// more or less light each bit of carving gets from the current light than
// from the soft frontal light it was photographed under.
//
// Coordinates: x right, y down the screen, z out of the screen to the viewer.
// Each rail has local coordinates u (along the outer edge) and v (across,
// from the outer edge inwards), matching `Rail` in frame_painter.dart.

#version 460 core
#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;           // whole frame, in logical pixels
uniform float uFaceWidth;     // moulding face width, in pixels
uniform float uPxPerMm;
uniform vec3 uLight;          // unit vector towards the light
uniform vec3 uTint;           // multiplied into the colour map
uniform vec2 uTexSize;        // colour map size, in image pixels
uniform float uTexScale;      // screen pixels per colour-map pixel
uniform float uGrainAngle;    // texture rotation, so grain runs along the rail
uniform float uMetallic;      // 0 = paint/wood, 1 = metal
uniform float uRoughness;     // multiplies the roughness map
uniform float uNormalStrength;
uniform float uStrip;         // 1 = photographed moulding strip
uniform float uMirror;        // 1 = mirror alternate strip tiles

uniform sampler2D uAlbedo;
uniform sampler2D uNormal;    // OpenGL convention (+y up)
uniform sampler2D uRoughMap;  // white = rough
uniform sampler2D uProfile;   // r: slope across the face, g: ambient occlusion

out vec4 fragColor;

const float PI = 3.14159265;
const float MAX_SLOPE = 6.0;  // must match profileLookupPixels() in Dart

vec2 rotate(vec2 v, float a) {
  float c = cos(a);
  float s = sin(a);
  return vec2(v.x * c - v.y * s, v.x * s + v.y * c);
}

void main() {
  vec2 p = FlutterFragCoord().xy;
  float w = uSize.x;
  float h = uSize.y;

  float dTop = p.y;
  float dRight = w - p.x;
  float dBottom = h - p.y;
  float dLeft = p.x;

  float rail;
  float angle;
  vec2 local;
  if (dTop <= dRight && dTop <= dBottom && dTop <= dLeft) {
    rail = 0.0; angle = 0.0; local = vec2(p.x, dTop);
  } else if (dRight <= dBottom && dRight <= dLeft) {
    rail = 1.0; angle = 0.5 * PI; local = vec2(p.y, dRight);
  } else if (dBottom <= dLeft) {
    rail = 2.0; angle = PI; local = vec2(w - p.x, dBottom);
  } else {
    rail = 3.0; angle = -0.5 * PI; local = vec2(h - p.y, dLeft);
  }

  float t = clamp(local.y / uFaceWidth, 0.0, 1.0);
  float slope;
  float occlusion;
  vec2 uv;
  float flipX = 1.0;

  if (uStrip > 0.5) {
    // The strip spans the face exactly and repeats along the rail, centred so
    // opposite rails match (as StripSkin does in frame_painter.dart). Its
    // profile and shadows are in the photo.
    float railLength = (rail == 0.0 || rail == 2.0) ? w : h;
    float tileLength = uTexSize.x * uTexScale;
    float offset = uMirror > 0.5 ? 0.5 * railLength : 0.5 * (railLength - tileLength);
    float x = (local.x - offset) / tileLength;
    if (uMirror > 0.5) {
      float m = mod(x, 2.0);
      if (m > 1.0) {
        x = 2.0 - m;
        flipX = -1.0;
      } else {
        x = m;
      }
    } else {
      x = fract(x);
    }
    uv = vec2(x, t);
    slope = 0.0;
    occlusion = 1.0;
  } else {
    // Profile across the face.
    vec4 profile = texture(uProfile, vec2(t, 0.5));
    slope = (profile.r * 2.0 - 1.0) * MAX_SLOPE;
    occlusion = profile.g;

    // Each rail is cut from a different part of the board, so the texture
    // doesn't continue around the corners.
    vec2 cut = local - rail * vec2(173.0, 61.0) * uPxPerMm;
    vec2 imagePx = rotate(cut, -uGrainAngle) / uTexScale;
    uv = fract(imagePx / uTexSize);
  }

  vec3 albedo = texture(uAlbedo, uv).rgb * uTint;
  vec3 mapNormal = texture(uNormal, uv).rgb * 2.0 - 1.0;
  mapNormal.y = -mapNormal.y;  // image rows run down
  mapNormal.x *= flipX;        // mirrored tiles face the other way
  float roughness = clamp(texture(uRoughMap, uv).r * uRoughness, 0.04, 1.0);

  // Where the surface rises towards the artwork it tilts towards the outer
  // edge (-v); the normal map adds the grain, brushing or hammering.
  vec2 detail = rotate(mapNormal.xy, uGrainAngle) * uNormalStrength;
  vec3 n = normalize(vec3(detail.x, detail.y - slope, 1.0));
  n.xy = rotate(n.xy, angle);

  vec3 L = uLight;
  vec3 V = vec3(0.0, 0.0, 1.0);

  // Matte light, scaled so a surface facing the viewer shows its true colour.
  float diffuse = 0.3 + 0.7 * max(dot(n, L), 0.0) / L.z;

  // Highlight: tight on smooth surfaces, broad and faint on rough ones.
  vec3 halfway = normalize(L + V);
  float shininess = mix(300.0, 6.0, sqrt(roughness));
  float highlight = pow(max(dot(n, halfway), 0.0), shininess) * (1.0 - 0.8 * roughness);

  // Metals show their surroundings: a ceiling much brighter than the floor,
  // and the lamp itself, blurred by roughness. Worked out in linear light,
  // since metal colour is reflectance (darkening it in display space turns
  // gold olive).
  vec3 reflected = reflect(-V, n);
  float ceiling = smoothstep(-0.4, 0.9, -reflected.y);
  float lampSpread = mix(40.0, 3.0, roughness);
  float lamp = pow(max(dot(reflected, L), 0.0), lampSpread) * mix(2.0, 0.6, roughness);
  float environment = 0.15 + 0.6 * ceiling + lamp;

  vec3 reflectance = pow(albedo, vec3(2.2));
  // Light bouncing between metal surfaces deepens the colour where it's dim.
  vec3 deepened = mix(reflectance * reflectance, reflectance, clamp(environment, 0.0, 1.0));
  vec3 metalLinear = deepened * environment + reflectance * 0.8 * highlight;
  vec3 metal = pow(clamp(metalLinear, 0.0, 1.0), vec3(1.0 / 2.2));

  vec3 dielectric = albedo * diffuse + vec3(0.22 * highlight);
  vec3 color = mix(dielectric, metal, uMetallic) * occlusion;

  if (uStrip > 0.5) {
    // Light now vs the soft frontal light of the photo (1 on flat parts).
    float now = 0.35 + 0.65 * max(dot(n, L), 0.0) / L.z;
    float photographed = 0.35 + 0.65 * n.z;
    float relight = clamp(now / photographed, 0.45, 1.7);
    // Gilding also glints where the carving catches the lamp.
    float glint = pow(max(dot(n, halfway), 0.0), 60.0);
    color = albedo * relight + albedo * 0.7 * glint;
  }

  fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
