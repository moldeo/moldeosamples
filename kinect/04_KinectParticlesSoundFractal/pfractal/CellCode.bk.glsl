#version 120
#extension GL_EXT_gpu_shader4 : enable

/**
* Se ocupa de copiar el código genético de padre a hijo...
*
* 0. Calcula a que Estado corresponde esta celda del código.
* 1. Calcular
* 2. Posiciona el cabezal de lectura en el código del padre
* 3. Mueve el cabezal de lectura a la misma posición relativa
* 4.
*
*/
struct ParticleState {
	float generation; /* src_state.x: [0.0f .. 1.0f]  step: (1.0f / K) = (1.0f / max_generations) */
	float division_age; /* src_state.y: [0.0f .. 1.0f] step: no-step */
	float age;  /* src_state.z: [0.0f .. 1.0f] step: 0.005f > must be time or tempo related */
	float origin;  /* src_state.w: [0..1] father generation > full age = (generation - origin) * 2 * max_scale_iterations + age  */
} PState;

uniform sampler2D src_tex_unit0;//cell code
uniform sampler2D src_tex_unit1;//cell memory
uniform sampler2D src_tex_unit2;//cell state

uniform sampler2D src_tex_unit3;//medium
uniform sampler2D src_tex_unit4;//altitude
uniform sampler2D src_tex_unit5;//variability
uniform sampler2D src_tex_unit6;//confidence

uniform vec2 src_tex_offset0;
uniform vec2 tempo_angle;
uniform vec2 dest_tex_size;

uniform float incremento_madurez;
uniform vec2 random_uniform;
uniform int random_color_function;
uniform int width;
uniform int height;
uniform int code;
uniform int memory;

float w = dest_tex_size.x;
float h = dest_tex_size.y;

int max_scale_iterations = int( log2(width) );
int max_generations = max_scale_iterations * 2;
float incremento_generacion = 1.0f / float(max_generations); /*2^8.0 = 16*16 = 256 particulas en la 8va generacion*/
//float incremento_madurez = 0.04f;
float madurez_reproductiva = 1.0f - incremento_madurez;//esto es un criterio... podria ser 0.8.. 1.0f muere!

float left_rep_maturity = madurez_reproductiva;
float right_rep_maturity = madurez_reproductiva;
float LEFTSTATE = 0.3f;
float RIGHTSTATE = 0.9f;

float ST_BORN = 0.3f;
float ST_RECYCLE = 0.9f;


/**

	i = posici�n de la columna
	j = posici�n de la fila
	ip = posicion de la columna del padre
	jp = posicion de la fila del padre

	is = posicion columna relativa a la escala s
	js = posicion columna relativa a la escala s

*/

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
			//fila impar y columna impar
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



void main(void)
{
    ParticleState State, FatherState;
    vec2 TCoordCode = gl_TexCoord[0].st;
    int i = int( floor( TCoordCode.s * w ) );
    int j = int( floor( TCoordCode.t * h ) );
    vec4 src_cellcode = texture2D(src_tex_unit0, TCoordCode );
    vec4 src_cellmemory = texture2D(src_tex_unit1, TCoordCode );

    int istate = int( floor( i / code ));
  	int jstate = int( floor( j / code ));
    vec2 TCoordState = vec2( float(istate) / float(width), float(jstate) / float(height));
    vec4 src_state = texture2D(src_tex_unit2, TCoordState );

    /// Start of code cluster: Cluester is 4 (rgba) * code * code float numbers!
    int icode0 = istate*code;
    int jcode0 = jstate*code;
    vec2 TCoordCode0 = vec2( float(icode0) / w, float(jcode0) / h );
    vec4 src_cellcode0 = texture2D(src_tex_unit0, TCoordCode0 );

    /// tomamos el vector posicion del padre (ip, jp, escala)
  	vec3 father_indexes = whereIsMyFather( istate, jstate, 0 );
  	int ipstate = int(father_indexes.x);
  	int jpstate = int(father_indexes.y);
    vec2 TCoordPState = vec2( float(ipstate) / float(width), float(jpstate) / float(height));
    vec4 src_pstate = texture2D(src_tex_unit2, TCoordPState );

    int ipcode0 = int( ipstate*code );
    int jpcode0 = int( jpstate*code );
    vec2 TCoordPCode0 = vec2( float(ipcode0) / w, float(jpcode0) / h );
    vec4 src_cellpcode0 = texture2D(src_tex_unit0, TCoordPCode0 );

    vec2 TCoordPCodeIJ = vec2( TCoordPCode0.s + float(i-icode0) / w, TCoordPCode0.t + float(j-jcode0) / h );
    vec4 src_cellpcode = texture2D(src_tex_unit0, TCoordPCodeIJ );
//    float rmotion = 0.5f*( 1.0f + cos( i*frac(random_uniform.x)-j*frac(random_uniform.x*1000.0f)) );



    State.generation = src_state.x;
    State.division_age = src_state.y;
    State.age = src_state.z;
    State.origin = src_state.w;

    FatherState.generation = src_pstate.x;
    FatherState.division_age = src_pstate.y;
    FatherState.age = src_pstate.z;
    FatherState.origin = src_pstate.w;


    //if cell state is born, and there is no code, take it from the father
    if (State.age==incremento_madurez && src_cellcode0.r == 0.0) {
      gl_FragColor = src_cellpcode;
      //gl_FragColor = vec4(0.1,0.1,0.1,0.1);
    } else {
      //DO NOTHING, JUST PASS IT BUT MARK POS0 with 0.000001 flag
      if ( i==icode0 && j==jcode0 ) {
        // Si hay un flag de CellBeginProgram : 1.0
        // la celda que le sigue es el id de ref del codigo a ejecutar (dentro del CellCode)
        // lo marcamos con 0.000001 para confirmar que fue chequeado
        if (src_cellcode.r==1.0) {
          gl_FragColor = vec4( src_cellcode.r+0.000001, src_cellcode.g, src_cellcode.b, src_cellcode.a);
        } else {
          //DO NOTHING, JUST PASS IT
          gl_FragColor = src_cellcode;
        }
      } else {
        //DO NOTHING, JUST PASS IT
        gl_FragColor = src_cellcode;
      }
    }
}
