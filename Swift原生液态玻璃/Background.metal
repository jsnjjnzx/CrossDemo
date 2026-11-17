#include <metal_stdlib>
using namespace metal;

struct Uniforms {
    float2 drawableSize;
    float2 logicalSize;
    float phase;
    float scene;
};

vertex float4 fullscreen(uint id [[vertex_id]]) {
    float2 vertices[] = {float2(-1, -1), float2(3, -1), float2(-1, 3)};
    return float4(vertices[id], 0, 1);
}

// Only the background is ported from the Qt demo; the system renders the glass.
fragment float4 background(float4 position [[position]], constant Uniforms &u [[buffer(0)]]) {
    float2 uv = position.xy / u.drawableSize;
    float2 p = (uv - 0.5) * float2(u.logicalSize.x / u.logicalSize.y, 1.0);
    float t = u.phase;
    float3 color;
    if (u.scene > 0.5) {
        float stripes = smoothstep(-0.035, 0.035, sin((uv.x + uv.y * 0.32 + t * 0.065) * 45.0));
        color = mix(float3(0.10, 0.21, 0.35), float3(0.89, 0.95, 0.97), stripes);
        float ribbon = exp(-pow((uv.y - 0.49 - 0.09 * sin(uv.x * 7.0 + t)) / 0.025, 2.0));
        color = mix(color, float3(1.0, 0.39, 0.18), ribbon);
    } else {
        float bend = p.x + p.y * 0.48 + 0.19 * sin(p.y * 3.8 + t * 0.34)
            + 0.10 * sin(p.x * 3.0 - t * 0.23);
        color = mix(float3(0.09, 0.33, 0.44), float3(0.35, 0.68, 0.76), smoothstep(-0.6, 0.6, p.y));
        color = mix(color, float3(0.91, 0.41, 0.28), smoothstep(-0.23, 0.04, bend));
        color = mix(color, float3(0.98, 0.74, 0.56), smoothstep(0.10, 0.31, bend));
        color = mix(color, float3(0.36, 0.20, 0.38), smoothstep(0.43, 0.65, bend));
        float ribbon = exp(-pow((bend - 0.055) / 0.024, 2.0));
        color += float3(0.24, 0.22, 0.17) * ribbon;
        float fine = exp(-pow((bend - 0.30) / 0.006, 2.0));
        color += float3(0.18, 0.12, 0.09) * fine;
        float2 delta = p - float2(-0.40 + 0.18 * sin(t * 0.3), -0.25);
        color += float3(0.09, 0.17, 0.15) * exp(-dot(delta, delta) * 4.0);
    }
    float grain = fract(sin(dot(uv * u.logicalSize, float2(12.9898, 78.233))) * 43758.5453) - 0.5;
    return float4(clamp(color + grain / 255.0, 0.0, 1.0), 1.0);
}
