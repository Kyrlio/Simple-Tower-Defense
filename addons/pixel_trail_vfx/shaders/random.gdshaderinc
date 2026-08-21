uint hash_uint(uint x)
{
    x ^= x >> 16U;
    x *= 0x7feb352dU;
    x ^= x >> 15U;
    x *= 0x846ca68bU;
    x ^= x >> 16U;
    return x;
}

float hash(float x)
{
    return float(hash_uint(uint(x))) * (1.0 / 4294967295.0);
}

float noise(float seed)
{
    float i = floor(seed);
    float f = fract(seed);

    float a = hash(i);
    float b = hash(i + 1.0);

    return mix(a, b, smoothstep(0.0, 1.0, f));
}

uint hash(uvec2 p)
{
    return hash_uint(p.x ^ hash_uint(p.y));
}

float quantizeEqualBins(float x, float levels)
{
    float q = min(floor(x * levels), levels - 1.0);
    return q / (levels - 1.0);
}

int quantizeEqualBinsInt(float x, float levels)
{
    float q = min(floor(x * levels), levels - 1.0);
    return int(q);
}

float random(vec2 p)
{
	uvec2 up = floatBitsToUint(p);
    return float(hash(up)) * (1.0 / 4294967295.0);
}