#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 viewportSize;
    float phase;
    float scene;
};

void main()
{
    vec2 uv = qt_TexCoord0;
    vec2 p = (uv - 0.5) * vec2(viewportSize.x / viewportSize.y, 1.0);
    float t = phase;
    vec3 color;
    if (scene > 0.5) {
        float stripes = smoothstep(-0.035, 0.035, sin((uv.x + uv.y * 0.32 + t * 0.065) * 45.0));
        color = mix(vec3(0.10, 0.21, 0.35), vec3(0.89, 0.95, 0.97), stripes);
        float ribbon = exp(-pow((uv.y - 0.49 - 0.09 * sin(uv.x * 7.0 + t)) / 0.025, 2.0));
        color = mix(color, vec3(1.0, 0.39, 0.18), ribbon);
    } else {
        float bend = p.x + p.y * 0.48 + 0.19 * sin(p.y * 3.8 + t * 0.34)
            + 0.10 * sin(p.x * 3.0 - t * 0.23);
        color = mix(vec3(0.09, 0.33, 0.44), vec3(0.35, 0.68, 0.76), smoothstep(-0.6, 0.6, p.y));
        color = mix(color, vec3(0.91, 0.41, 0.28), smoothstep(-0.23, 0.04, bend));
        color = mix(color, vec3(0.98, 0.74, 0.56), smoothstep(0.10, 0.31, bend));
        color = mix(color, vec3(0.36, 0.20, 0.38), smoothstep(0.43, 0.65, bend));
        float ribbon = exp(-pow((bend - 0.055) / 0.024, 2.0));
        color += vec3(0.24, 0.22, 0.17) * ribbon;
        float fine = exp(-pow((bend - 0.30) / 0.006, 2.0));
        color += vec3(0.18, 0.12, 0.09) * fine;
        float halo = exp(-dot(p - vec2(-0.40 + 0.18 * sin(t * 0.3), -0.25),
                                   p - vec2(-0.40 + 0.18 * sin(t * 0.3), -0.25)) * 4.0);
        color += vec3(0.09, 0.17, 0.15) * halo;
    }
    float grain = fract(sin(dot(uv * viewportSize, vec2(12.9898, 78.233))) * 43758.5453) - 0.5;
    color += grain / 255.0;
    fragColor = vec4(clamp(color, 0.0, 1.0), 1.0) * qt_Opacity;
}
