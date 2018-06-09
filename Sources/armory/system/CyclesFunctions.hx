package armory.system;

class CyclesFunctions {

	public static var str_tex_checker = "
	vec3 tex_checker(const vec3 co, const vec3 col1, const vec3 col2, const float scale) {
		vec3 p = (co + 0.000001 * 0.999999) * scale;
		float xi = abs(floor(p.x));
		float yi = abs(floor(p.y));
		float zi = abs(floor(p.z));
		bool check = ((mod(xi, 2.0) == mod(yi, 2.0)) == bool(mod(zi, 2.0)));
		return check ? col1 : col2;
	}
	vec3 tex_checker(const vec2 co, const vec3 col1, const vec3 col2, const float scale) {
		return tex_checker(vec3(co.x, co.y, 1.0), col1, col2, scale);
	}
	";

	// Created by inigo quilez - iq/2013
	// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
	//vec3 hash(vec3 x) {
		//return texture(snoise, (x.xy + vec2(3.0, 1.0) * x.z + 0.5) / 64.0, -100.0).xyz;
		//x = vec3(dot(x, vec3(127.1, 311.7, 74.7)),
		//         dot(x, vec3(269.5, 183.3, 246.1)),
		//         dot(x, vec3(113.5, 271.9, 124.6)));
		//return fract(sin(x) * 43758.5453123);
	//}
	public static var str_tex_voronoi = "
	vec4 tex_voronoi(const vec3 x) {
		vec3 p = floor(x);
		vec3 f = fract(x);
		float id = 0.0;
		float res = 100.0;
		for (int k = -1; k <= 1; k++)
		for (int j = -1; j <= 1; j++)
		for (int i = -1; i <= 1; i++) {
			vec3 b = vec3(float(i), float(j), float(k));
			vec3 pb = p + b;
			//vec3 r = vec3(b) - f + texture(snoise, (pb.xy + vec2(3.0, 1.0) * pb.z + 0.5) / 64.0, -100.0).xyz; // No bias in tese
			vec3 r = vec3(b) - f + texture(snoise, (pb.xy + vec2(3.0, 1.0) * pb.z + 0.5) / 64.0).xyz;
			//vec3 r = vec3(b) - f + hash(p + b);
			float d = dot(r, r);
			if (d < res) {
				id = dot(p + b, vec3(1.0, 57.0, 113.0));
				res = d;
			}
		}
		vec3 col = 0.5 + 0.5 * cos(id * 0.35 + vec3(0.0, 1.0, 2.0));
		return vec4(col, sqrt(res));
	}
	vec4 tex_voronoi(const vec2 x) {
		return tex_voronoi(vec3(x.x, x.y, 1.0));
	}
	";

	// public static var str_tex_noise = "
	// float tex_noise_f(const vec3 x) {
	//     vec3 p = floor(x);
	//     vec3 f = fract(x);
	//     f = f * f * (3.0 - 2.0 * f);
	//     vec2 uv = (p.xy + vec2(37.0, 17.0) * p.z) + f.xy;
	//     vec2 rg = texture(snoisea, (uv + 0.5) / 64.0, -100.0).yx;
	//     return mix(rg.x, rg.y, f.z);
	// }
	// float tex_noise(vec3 q) {
	//     //return fract(sin(dot(q.xy, vec2(12.9898,78.233))) * 43758.5453);
	//     q *= 2.0; // Match to Cycles
	//     const mat3 m = mat3(0.00, 0.80, 0.60, -0.80, 0.36, -0.48, -0.60, -0.48, 0.64);
	//     float f = 0.5000 * tex_noise_f(q); q = m * q * 2.01;
	//     f += 0.2500 * tex_noise_f(q); q = m * q * 2.02;
	//     f += 0.1250 * tex_noise_f(q); q = m * q * 2.03;
	//     f += 0.0625 * tex_noise_f(q); q = m * q * 2.01;
	//     return pow(f, 3.0);
	// }
	// "
	// Created by Nikita Miropolskiy, nikat/2013
	// Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License
	public static var str_tex_noise = "
	vec3 random3(const vec3 c) {
		// Might not be precise on lowp floats
		float j = 4096.0 * sin(dot(c, vec3(17.0, 59.4, 15.0)));
		vec3 r;
		r.z = fract(512.0 * j);
		j *= 0.125;
		r.x = fract(512.0 * j);
		j *= 0.125;
		r.y = fract(512.0 * j);
		return r - 0.5;
	}
	float tex_noise_f(const vec3 p) {
		const float F3 = 0.3333333;
		const float G3 = 0.1666667;
		vec3 s = floor(p + dot(p, vec3(F3)));
		vec3 x = p - s + dot(s, vec3(G3));
		vec3 e = step(vec3(0.0), x - x.yzx);
		vec3 i1 = e*(1.0 - e.zxy);
		vec3 i2 = 1.0 - e.zxy*(1.0 - e);
		vec3 x1 = x - i1 + G3;
		vec3 x2 = x - i2 + 2.0*G3;
		vec3 x3 = x - 1.0 + 3.0*G3;
		vec4 w, d;
		w.x = dot(x, x);
		w.y = dot(x1, x1);
		w.z = dot(x2, x2);
		w.w = dot(x3, x3);
		w = max(0.6 - w, 0.0);
		d.x = dot(random3(s), x);
		d.y = dot(random3(s + i1), x1);
		d.z = dot(random3(s + i2), x2);
		d.w = dot(random3(s + 1.0), x3);
		w *= w;
		w *= w;
		d *= w;
		return clamp(dot(d, vec4(52.0)), 0.0, 1.0);
	}
	float tex_noise(const vec3 p) {
		return 0.5333333 * tex_noise_f(0.5 * p)
			+ 0.2666667 * tex_noise_f(p)
			+ 0.1333333 * tex_noise_f(2.0 * p)
			+ 0.0666667 * tex_noise_f(4.0 * p);
	}
	float tex_noise(const vec2 p) {
		return tex_noise(vec3(p.x, p.y, 1.0));
	}
	";

	public static var str_hsv_to_rgb = "
	vec3 hsv_to_rgb(const vec3 c) {
	  const vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	  vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	  return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
	}
	";

	public static var str_rgb_to_hsv = "
	vec3 rgb_to_hsv(const vec3 c) {
		const vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
		vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
		vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

		float d = q.x - min(q.w, q.y);
		float e = 1.0e-10;
		return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
	}
	";

	// https://twitter.com/Donzanoid/status/903424376707657730
	public static var str_wavelength_to_rgb = "
	vec3 wavelength_to_rgb(const float t) {
	    vec3 r = t * 2.1 - vec3(1.8, 1.14, 0.3);
	    return 1.0 - r * r;
	}
	";

	public static var str_traceAO = "
	float traceConeAO(sampler3D voxels, const vec3 origin, vec3 dir, const float aperture, const float maxDist, const float offset) {
		const ivec3 voxelgiResolution = ivec3(256, 256, 256);
		const float voxelgiStep = 1.0;
		const float VOXEL_SIZE = (2.0 / voxelgiResolution.x) * voxelgiStep;
		dir = normalize(dir);
		float sampleCol = 0.0;
		float dist = offset;
		float diam = dist * aperture;
		vec3 samplePos;
		while (sampleCol < 1.0 && dist < maxDist) {
			samplePos = dir * dist + origin;
			float mip = max(log2(diam * voxelgiResolution.x), 0);
			float mipSample = textureLod(voxels, samplePos * 0.5 + vec3(0.5), mip).r;
			sampleCol += (1 - sampleCol) * mipSample;
			dist += max(diam / 2, VOXEL_SIZE);
			diam = dist * aperture;
		}
		return sampleCol;
	}
	vec3 tangent(const vec3 n) {
		vec3 t1 = cross(n, vec3(0, 0, 1));
		vec3 t2 = cross(n, vec3(0, 1, 0));
		if (length(t1) > length(t2)) return normalize(t1);
		else return normalize(t2);
	}
	float traceAO(const vec3 origin, const vec3 normal, sampler3D voxels) {
		const float TAN_22_5 = 0.55785173935;
		const float angleMix = 0.5f;
		const float aperture = TAN_22_5;
		vec3 o1 = normalize(tangent(normal));
		vec3 o2 = normalize(cross(o1, normal));
		vec3 c1 = 0.5f * (o1 + o2);
		vec3 c2 = 0.5f * (o1 - o2);
		const float voxelgiOffset = 2.5;
		const float voxelgiRange = 2.0;
		const float MAX_DISTANCE = 1.73205080757 * voxelgiRange;
		const ivec3 voxelgiResolution = ivec3(256, 256, 256);
		const float voxelgiStep = 1.0;
		const float VOXEL_SIZE = (2.0 / voxelgiResolution.x) * voxelgiStep;
		const float offset = 1.5 * VOXEL_SIZE * voxelgiOffset;
		float col = traceConeAO(voxels, origin, normal, aperture, MAX_DISTANCE, offset);
		col += traceConeAO(voxels, origin, mix(normal, o1, angleMix), aperture, MAX_DISTANCE, offset);
		col += traceConeAO(voxels, origin, mix(normal, o2, angleMix), aperture, MAX_DISTANCE, offset);
		col += traceConeAO(voxels, origin, mix(normal, -c1, angleMix), aperture, MAX_DISTANCE, offset);
		col += traceConeAO(voxels, origin, mix(normal, -c2, angleMix), aperture, MAX_DISTANCE, offset);
		col += traceConeAO(voxels, origin, mix(normal, -o1, angleMix), aperture, MAX_DISTANCE, offset);
		col += traceConeAO(voxels, origin, mix(normal, -o2, angleMix), aperture, MAX_DISTANCE, offset);
		col += traceConeAO(voxels, origin, mix(normal, c1, angleMix), aperture, MAX_DISTANCE, offset);
		col += traceConeAO(voxels, origin, mix(normal, c2, angleMix), aperture, MAX_DISTANCE, offset);
		const float blendFac = 1.0;
		return col / (9.0 * blendFac);
	}
	";

	public static var str_cotangentFrame = "
	mat3 cotangentFrame(const vec3 n, const vec3 p, const vec2 duv1, const vec2 duv2) {
		vec3 dp1 = dFdx(p);
		vec3 dp2 = dFdy(p);
		vec3 dp2perp = cross(dp2, n);
		vec3 dp1perp = cross(n, dp1);
		vec3 t = dp2perp * duv1.x + dp1perp * duv2.x;
		vec3 b = dp2perp * duv1.y + dp1perp * duv2.y;
		float invmax = inversesqrt(max(dot(t, t), dot(b, b)));
		return mat3(t * invmax, b * invmax, n);
	}
	mat3 cotangentFrame(const vec3 n, const vec3 p, const vec2 texCoord) {
		return cotangentFrame(n, p, dFdx(texCoord), dFdy(texCoord));
	}
	";

	public static var str_octahedronWrap = "
	vec2 octahedronWrap(const vec2 v) {
		return (1.0 - abs(v.yx)) * (vec2(v.x >= 0.0 ? 1.0 : -1.0, v.y >= 0.0 ? 1.0 : -1.0));
	}
	";

	public static var str_packFloat = "
	float packFloat(const float f1, const float f2) {
		return floor(f1 * 100.0) + min(f2, 1.0 - 1.0 / 100.0);
	}
	";

	public static var str_packFloat2 = "
	float packFloat2(const float f1, const float f2) {
		return floor(f1 * 255.0) + min(f2, 1.0 - 1.0 / 100.0);
	}
	";
}
