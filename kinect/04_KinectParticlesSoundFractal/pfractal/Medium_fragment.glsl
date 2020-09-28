#extension GL_EXT_gpu_shader4 : enable

uniform sampler2D src_tex_unit0;
uniform vec2 src_tex_offset0;
uniform vec2 tempo_angle;
uniform vec2 dest_tex_size;

float w = dest_tex_size.x;
float h = dest_tex_size.y;

void main(void)
{
  vec4 src_medium = texture2D( src_tex_unit0, gl_TexCoord[0].st );
  //vec4 loaded_medium = texture2D( src_tex_unit1, gl_TexCoord[0].st );
	vec2 TCoord = gl_TexCoord[0].st;

  gl_FragColor = vec4(0.0f,0.0f,0.0f,0.0f);

}
