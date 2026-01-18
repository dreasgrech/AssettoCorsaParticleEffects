float2 hash2(float2 p) {
  p = float2(dot(p, float2(127.1, 311.7)),
             dot(p, float2(269.5, 183.3)));
  return -1.0 + 2.0 * frac(sin(p) * 43758.5453123);
}

float noise2(float2 p) {
  const float K1 = 0.366025404;
  const float K2 = 0.211324865;

  float2 i = floor(p + (p.x + p.y) * K1);

  float2 a = p - i + (i.x + i.y) * K2;
  float2 o = (a.x > a.y) ? float2(1.0, 0.0) : float2(0.0, 1.0);
  float2 b = a - o + K2;
  float2 c = a - 1.0 + 2.0 * K2;

  float3 h = max(0.5 - float3(dot(a, a), dot(b, b), dot(c, c)), 0.0);
  float3 n = h*h*h*h * float3(dot(a, hash2(i + 0.0)),
                              dot(b, hash2(i + o)),
                              dot(c, hash2(i + 1.0)));
  return dot(n, float3(70.0, 70.0, 70.0));
}

float fbm(float2 uv) {
  float f;
  float2x2 m = float2x2(1.6, 1.2, -1.2, 1.6);
  f  = 0.5000 * noise2(uv); uv = mul(m, uv);
  f += 0.2500 * noise2(uv); uv = mul(m, uv);
  f += 0.1250 * noise2(uv); uv = mul(m, uv);
  f += 0.0625 * noise2(uv); uv = mul(m, uv);
  return 0.5 + 0.5 * f;
}

float4 main(PS_IN pin) {
  float2 uv = pin.Tex;
  float2 q  = uv;
  q.y *= 2.0;

  float strength = max(0.001, gStrength);

  float T3 = max(3.0, 1.25 * strength) * gTime;

  q.x -= 0.5;
  q.y -= 0.25;

  float n = fbm(strength * q - float2(0.0, T3) + gSeed);

  float widthBase   = 1.65 + 0.18 * strength;
  float widthTaper  = 1.35 + 0.12 * strength;
  float heightScale = 0.75;
  float noiseMask   = 0.25;

  float edgeMul = 16.0;
  float edgePow = 1.15;

  float2 qq = q * float2(widthBase + q.y * widthTaper, heightScale);
  float core = max(0.0, length(qq) - n * max(0.0, q.y + noiseMask));
  float c = 1.0 - edgeMul * pow(core, edgePow);

  float c1 = n * c * (1.5 - pow(1.25 * uv.y, 4.0));
  c1 = saturate(c1);

  float3 col = float3(
    1.5 * c1,
    1.5 * c1*c1*c1,
    pow(c1, 6.0)
  );

  float a = saturate(c * (1.0 - pow(uv.y, 3.0)));
  float3 rgb = (col * a) * gIntensity;

  return float4(rgb, a);
  //return float4(float3(0,0,0), 0);
}
