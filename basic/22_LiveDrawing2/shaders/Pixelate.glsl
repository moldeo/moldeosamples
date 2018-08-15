uniform sampler2D src_tex_unit0;
uniform vec2 src_tex_offset0;
uniform vec2 tempo_angle;
uniform vec2 dest_tex_size;

void main(void)
{
    int n = 30;
    float d = 1.0 / n;
    vec2 tex_coords = gl_TexCoord[0].st;

    float s = (n * (int)(tex_coords.s * dest_tex_size.x / n) + d) / dest_tex_size.x;
    float t = (n * (int)(tex_coords.t * dest_tex_size.y / n) + d) / dest_tex_size.y;
    
    gl_FragColor = texture2D(src_tex_unit0, vec2(s, t)).rgba;
}