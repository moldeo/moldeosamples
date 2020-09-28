uniform sampler2D src_tex_unit0;
uniform sampler2D src_tex_unit1;
uniform vec2 src_tex_offset0;
uniform vec2 tempo_angle;
uniform vec2 dest_tex_size;

void main(void)
{
    vec4 src_color = texture2D(src_tex_unit0, gl_TexCoord[0].st);
	
	
	
	
	gl_FragColor = src_color;
}
