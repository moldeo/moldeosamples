#version 120
#extension GL_EXT_gpu_shader4 : enable

uniform sampler2D src_tex_unit0;// scale

void main(void)
{
		vec4 src_scale = texture2D(src_tex_unit0, gl_TexCoord[0].st);
		gl_FragColor = vec4( src_scale.r, 0.0f, 1.0f, 1.0f);
}
