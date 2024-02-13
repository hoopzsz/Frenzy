////
////  Interstellar.metal
////  Tombola
////
////  Created by Daniel Hooper on 2024-02-11.
////
//
//#include <metal_stdlib>
//
//using namespace metal;
//
//const float tau = 6.28318530717958647692;
//
//// Gamma correction
//#define GAMMA (2.2)
//
//float3 ToLinear(float3 col) {
//    // Simulate a monitor, converting color values into light values
//    return pow(col, float3(GAMMA));
//}
//
//float3 ToGamma(float3 col) {
//    // Convert back into color values, so the correct light will come out of the monitor
//    return pow(col, float3(1.0 / GAMMA));
//}
//
//float4 Noise(texture2d<float> texture, int2 x) {
//    return texture.sample(texture.coord + (float2(x) + 0.5) / 256.0, -100.0);
//}
//
//float4 Rand(texture2d<float> texture, int x) {
//    float2 uv;
//    uv.x = (float(x) + 0.5) / 256.0;
//    uv.y = (floor(uv.x) + 0.5) / 256.0;
//    return texture.sample(uv, -100.0);
//}
//
//kernel void mainImage(texture2d<float, access::write> fragColor [[texture(0)]],
//                       constant float2& iResolution [[buffer(0)]],
//                       constant float& iTime [[buffer(1)]],
//                       float2 fragCoord [[thread_position_in_grid]]) {
//    float3 ray;
//    ray.xy = 2.0 * (fragCoord - iResolution * 0.5) / iResolution.x;
//    ray.z = 1.0;
//
//    float offset = iTime * 0.5;
//    float speed2 = (cos(offset) + 1.0) * 2.0;
//    float speed = speed2 + 0.1;
//    offset += sin(offset) * 0.96;
//    offset *= 2.0;
//
//    float3 col = float3(0);
//
//    float3 stp = ray / max(abs(ray.x), abs(ray.y));
//
//    float2 pos = 2.0 * stp + 0.5;
//    for (int i = 0; i < 20; i++) {
//        float z = Noise(texture, int2(pos)).x;
//        z = fract(z - offset);
//        float d = 50.0 * z - pos.y;
//        float w = pow(max(0.0, 1.0 - 8.0 * length(fract(pos) - 0.5)), 2.0);
//        float3 c = max(float3(0), float3(1.0 - abs(d + speed2 * 0.5) / speed, 1.0 - abs(d) / speed, 1.0 - abs(d - speed2 * 0.5) / speed));
//        col += 1.5 * (1.0 - z) * c * w;
//        pos += stp.xy;
//    }
//
//    fragColor.write(float4(ToGamma(col), 1.0), fragCoord);
//}
//
//
