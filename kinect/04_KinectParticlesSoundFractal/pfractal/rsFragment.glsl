#version 330
//precision mediump float;
uniform sampler2D t_image;
uniform sampler2DArray t_array;
uniform sampler2D t_image_2;
uniform vec3 a_light;

uniform float texture_opacity;
uniform float texture_2_opacity;

in vec4 vertex_color;
in vec2 vertex_coord;
in vec2 vertex_coord_2;
in float vertex_id;
in float vertex_material;
in vec3 vertex_normal;
in vec3 v_eye;
           //"in vec4 vertex_normal;

void main() {
 vec4 texcolor = texture2D( t_image, vertex_coord );
 vec4 texcolor_2 = texture2D( t_image_2, vertex_coord_2 );
           //" int layer =  int(vertex_id);
 float ffmaterial = floor(vertex_material + 0.5);
 int layer =  int(ffmaterial);
           //" float ffid = fvertex_id*0.00001;
	vec4 texcolorA = texture( t_array, vec3(vertex_coord.s, vertex_coord.t, layer ) );
  float intensity = 0.6+0.4*abs(max( 0.0, dot( vertex_normal.xyz, -1.0*a_light )) );
           //"	float intensity = 1.0;
           //" if (vertex_coord.s<0.0 || vertex_coord.s>1.0 || vertex_coord.t<0.0 || vertex_coord.t>1.0 ) texcolor = vec4( 0,0,0,0);
           //"	vec4 mulcolor = intensity*vec4( 1.0*vertex_color.r, 1.0*vertex_color.g, 1.0*vertex_color.b, 1.0*vertex_color.a );
	///gl_FragColor = vec4( texcolorA.r*vertex_color.r, texcolorA.g*vertex_color.g, texcolorA.b*vertex_color.b, vertex_color.a*texcolorA.a);
           //"	gl_FragColor = vec4( vertex_id*0.1, texcolorA.g*vertex_color.g, texcolorA.b*vertex_color.b, vertex_color.a*texcolorA.a);
  //gl_FragColor = vec4( 1.0, 1.0, 1.0, 1.0);

  	gl_FragColor = vec4(
      intensity*vertex_color.r*(texture_opacity*texcolor.r+texture_2_opacity*texcolor_2.r),
      intensity*vertex_color.g*(texture_opacity*texcolor.g+texture_2_opacity*texcolor_2.g),
      intensity*vertex_color.b*(texture_opacity*texcolor.b+texture_2_opacity*texcolor_2.b),
      vertex_color.a*(texture_opacity*texcolor.a+texture_2_opacity*texcolor_2.a));
}
