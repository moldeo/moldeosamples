#define KERNEL_SIZE 9

// Gaussian kernel
// 1 2 1    0 1 2
// 2 4 2    3 4 5
// 1 2 1    6 7 9
float kernel[KERNEL_SIZE];

uniform sampler2D src_tex_unit0;
uniform vec2 src_tex_offset0;
uniform vec2 tempo_angle;
uniform float fade_const;

vec2 offset[KERNEL_SIZE];

void main(void)
{
    int i = 0;
    vec4 sum = vec4(0.0);

    offset[0] = vec2(-src_tex_offset0.s, -src_tex_offset0.t);
    offset[1] = vec2(0.0, -src_tex_offset0.t);
    offset[2] = vec2(src_tex_offset0.s, -src_tex_offset0.t);

    offset[3] = vec2(-src_tex_offset0.s, 0.0);
    offset[4] = vec2(0.0, 0.0);
    offset[5] = vec2(src_tex_offset0.s, 0.0);

    offset[6] = vec2(-src_tex_offset0.s, src_tex_offset0.t);
    offset[7] = vec2(0.0, src_tex_offset0.t);
    offset[8] = vec2(src_tex_offset0.s, src_tex_offset0.t);

    kernel[0] = 1.0/16.0;   kernel[1] = 2.0/16.0;   kernel[2] = 1.0/16.0;
    kernel[3] = 2.0/16.0;   kernel[4] = 4.0/16.0;   kernel[5] = 2.0/16.0;
    kernel[6] = 1.0/16.0;   kernel[7] = 2.0/16.0;   kernel[8] = 1.0/16.0;

    for (i = 0; i < 4; i++)
    {
        vec4 tmp = texture2D(src_tex_unit0, gl_TexCoord[0].st + offset[i]);
        sum += tmp * kernel[i];
    }

    for (i = 5; i < KERNEL_SIZE; i++)
    {
        vec4 tmp = texture2D(src_tex_unit0, gl_TexCoord[0].st + offset[i]);
        sum += tmp * kernel[i];
    }

	vec4 color0 = texture2D(src_tex_unit0, gl_TexCoord[0].st + offset[4]);
    sum += color0 * kernel[4];

    gl_FragColor = (1.0 - fade_const) * color0 +  fade_const * vec4(sum.rgb, 1.0);
}
