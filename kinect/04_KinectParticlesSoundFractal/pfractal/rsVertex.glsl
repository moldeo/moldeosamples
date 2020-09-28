#version 330

in vec4 position;
in vec4 scale;
in vec4 orientation;
in vec4 colors;
in vec4 normal;

//"in vec4 materials;
//uniform sampler2D t_cellcode;
uniform sampler2D t_cellmem;
uniform sampler2D t_cellstate;

uniform mat4 projmatrix;
uniform vec3 color;
uniform vec3 scalev;
uniform float opacity;
uniform int mcols=256;
uniform int mrows=256;
uniform vec3 eye;

out mat4 pmatrix;
out float fcols;
out float frows;
out vec3 veye;
//"attribute vec2 t_coord;
//"attribute vec3 normal;
//"out vec4 vertex_color;
//"out vec4 vertex_normal;
//"out vec2 vertex_coord;

out VertexAttrib {
            //" vec2 texcoord;
 vec4 color;
 vec4 position;
 vec4 scale;
 float ffvid;
 float material;
 vec4 normal;
 vec4 orientation;
 int i;
 int j;
 int ip;
 int jp;
 float age;
} vertex;

int max_scale_iterations;
int max_generations;


vec3 whereIsMyFather( int i, int j, int scale ) {

	int iteration = 0;
	int is = i;
	int js = j;

	int ip = is;
	int jp = js;
	int i_pow2 = is & 1;
	int j_pow2 = js & 1;

	int pow2s = 1;

	for( iteration = 0; iteration < max_scale_iterations ; iteration++ ) {

		if ( j_pow2==1 ) {
			//fila impar
			jp = js - 1;
			break;

		} else
		if ( j_pow2==0 && i_pow2==1 ) {
			//fila par y columna impar
			ip = is - 1;
			break;
		}
		else
		if ( i_pow2==0 && j_pow2==0 ) {
			//fila impar y columna impTCoordMediumar
			//return whereIsMyFather( i, j, scale+1 );
			i = i >> 1;
			j = j >> 1;
			scale = scale + 1;

			is = i;
			js = j;
			ip = is;
			jp = js;
			i_pow2 = is & 1;
			j_pow2 = js & 1;
		}

	}

	if ( scale>0 ) pow2s = 1 << scale;

	//for( int k=1, int p=0; p<scale; k*=2, p++ );
	//return position in texture ( 0..(cols-1), and 0..(rows-1)) of the father pixel position

	return vec3( ip*pow2s, jp*pow2s, float(scale) );


}

void main() {
 int vid = gl_VertexID;
 float fvid = float(vid);
 fcols = float(mcols);
 frows = float(mrows);
 float vj = floor(fvid / fcols);
 float vi = fvid - vj*fcols;
 float f_j = (vj) / frows;
 float f_i = (vi) / fcols;

 max_scale_iterations = int( log2(fcols) );
 max_generations = max_scale_iterations * 2;

            //"vertex.texcoord = t_coord;
            //"	vec4 vertex01 = vec4( position.x, position.y-0.4, position.z, 1.0);
            //"	vec4 vertex02 = vec4( position.x-0.5, position.y+0.1, position.z, 1.0);
            //"	vec4 vertex03 = vec4( position.x+0.5, position.y+0.1, position.z, 1.0);
            //"	vec4 vfinal = (position.w-0.1)*(position.w-0.2)*vertex03/(0.1*0.2);
            //"	vec4 vfinal = (position.w-0.1)*(position.w-0.2)*vertex03/(0.1*0.2);
  vertex.position = position;
  gl_Position = position;
  vertex.color = vec4( colors.r*color.r, colors.g*color.g, colors.b*color.b, opacity*colors.a);
  vertex.normal = normal;
  vertex.scale = vec4(scale.x*scalev.x, scale.y*scalev.y, scale.z*scalev.z, 1.0);
  vertex.ffvid = fvid;
  vertex.material = texture2D( t_cellmem, vec2( f_i, f_j ) ).r;
  vertex.age = texture2D( t_cellstate, vec2( f_i, f_j ) ).b;
  vertex.orientation = orientation;
  vertex.i = int(vi);
  vertex.j = int(vj);

  vec3 father_indexes = whereIsMyFather( vertex.i, vertex.j, 0 );
  int ip = int(father_indexes.x);
  int jp = int(father_indexes.y);
  vertex.ip = ip;
  vertex.jp = jp;
            //"vertex.material = materials.x;
            //"vertex.material = fvid;

            //"vertex_color = vec4( color.rgb,opacity) + colors;
            //"vertex_normal = orientation;
            //"vertex_coord = vec2(0.5,0.5);
pmatrix = projmatrix;
veye = eye;
            //"vertex_coord = scale;
            //"	gl_Position = position;
}
