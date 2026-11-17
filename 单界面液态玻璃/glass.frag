#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 viewportSize;
    vec4 panelRect;
    vec2 pointerPosition;
    float strength;
    float frost;
    float solid;
};
layout(binding = 1) uniform sampler2D background;

vec3 sampleScene(vec2 uv, vec2 blur)
{
    vec3 c = texture(background, uv).rgb * 0.28;
    c += texture(background, uv + vec2(blur.x, 0)).rgb * 0.12;
    c += texture(background, uv - vec2(blur.x, 0)).rgb * 0.12;
    c += texture(background, uv + vec2(0, blur.y)).rgb * 0.12;
    c += texture(background, uv - vec2(0, blur.y)).rgb * 0.12;
    c += texture(background, uv + blur).rgb * 0.06;
    c += texture(background, uv - blur).rgb * 0.06;
    c += texture(background, uv + vec2(blur.x, -blur.y)).rgb * 0.06;
    c += texture(background, uv + vec2(-blur.x, blur.y)).rgb * 0.06;
    return c;
}

void main()
{
    vec2 pixel = qt_TexCoord0 * viewportSize;
    vec2 halfSize = panelRect.zw * 0.5;
    vec2 center = panelRect.xy + halfSize;
    vec2 p = pixel - center;
    float radius = min(56.0, halfSize.y * 0.30);
    vec2 q = abs(p) - (halfSize - radius);
    vec2 outside = max(q, 0.0);
    float d = length(outside) + min(max(q.x, q.y), 0.0) - radius;
    float aa = max(fwidth(d), 0.5);
    float mask = 1.0 - smoothstep(-aa, aa, d);
    float shadow = 0.20 * exp(-max(d, 0.0) / 17.0) * smoothstep(-1.0, 8.0, d);
    if (mask < 0.001) {
        fragColor = vec4(vec3(0.025, 0.035, 0.05) * shadow, shadow) * qt_Opacity;
        return;
    }
    vec2 normalXY = length(outside) > 0.001 ? normalize(outside) * sign(p)
        : (q.x > q.y ? vec2(sign(p.x), 0.0) : vec2(0.0, sign(p.y)));
    float bevel = clamp(-d / 28.0, 0.0, 1.0);
    float slope = 1.0 - bevel;
    vec3 normal = vec3(normalXY * slope, sqrt(max(0.0001, 1.0 - slope * slope)));
    vec3 ray = refract(vec3(0.0, 0.0, -1.0), normal, 1.0 / 1.46);
    vec2 offset = ray.xy / max(abs(ray.z), 0.2) * 42.0 * strength;
    // A shallow inner lens keeps the broad face transparent while the bevel bends sharply.
    offset += p / max(halfSize, vec2(1.0)) * 2.2 * strength;
    vec2 uv = clamp((pixel + offset) / viewportSize, vec2(0.001), vec2(0.999));
    vec2 blur = vec2(0.7 + frost * 5.0) / viewportSize;
    vec3 color = sampleScene(uv, blur);
    vec2 dispersion = normalXY * pow(slope, 2.0) * strength * 1.25 / viewportSize;
    color.r = mix(color.r, texture(background, uv + dispersion).r, 0.65);
    color.b = mix(color.b, texture(background, uv - dispersion).b, 0.65);
    float luminance = dot(color, vec3(0.2126, 0.7152, 0.0722));
    color = mix(vec3(luminance), color, 1.10);
    color = mix(color, vec3(0.86, 0.93, 0.96), 0.055 + frost * 0.12);
    float fresnel = pow(1.0 - normal.z, 3.0);
    vec2 light = normalize(vec2(-0.65, -0.85));
    float directional = dot(normalXY, light);
    float thinRim = exp(-abs(d + 0.9) / 0.8);
    float innerRim = exp(-abs(d + 5.0) / 3.5);
    vec2 pointerDelta = pointerPosition - pixel;
    float proximity = exp(-dot(pointerDelta, pointerDelta) / 42000.0);
    vec2 pointerLight = pointerDelta / max(length(pointerDelta), 1.0);
    float movingHighlight = pow(max(dot(normalXY, pointerLight), 0.0), 5.0) * proximity;
    color += vec3(0.84, 0.94, 1.0) * (thinRim * (0.30 + 0.28 * directional)
        + fresnel * 0.11 + innerRim * movingHighlight * 0.30);
    color -= vec3(0.13, 0.14, 0.16) * innerRim * max(-directional, 0.0) * 0.35;
    color = mix(color, vec3(0.18, 0.23, 0.29), solid);
    fragColor = vec4(clamp(color, 0.0, 1.0) * mask, mask) * qt_Opacity;
}
