uniform sampler2D src_tex_unit0;
uniform mat4 par_mat4;

void main(void)
{
	vec4 TexColor = texture2D(src_tex_unit0, gl_TexCoord[0].st);
	gl_FragColor = TexColor * par_mat4;
}
