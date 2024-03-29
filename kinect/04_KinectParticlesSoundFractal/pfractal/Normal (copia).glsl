#version 120
#extension GL_EXT_gpu_shader4 : enable

uniform sampler2D src_tex_unit0;// state
uniform sampler2D src_tex_unit1;// velocity
uniform sampler2D src_tex_unit2;// position
uniform sampler2D src_tex_unit3;// normal
uniform sampler2D src_tex_unit4;// scale

uniform sampler2D src_tex_unit5;//cell code
uniform sampler2D src_tex_unit6;//medium

uniform sampler2D src_tex_unit7;//confidence

uniform vec2 src_tex_offset0;
uniform vec2 tempo_angle;
uniform vec2 dest_tex_size;
uniform vec2 random_uniform;

uniform float incremento_madurez;

uniform int maxage;
//uniform int emitionperiod;
//uniform int emitionrate;
uniform int randommethod;
uniform int creationmethod;

uniform int emittertype;
uniform float emittervectorx;
uniform float emittervectory;
uniform float emittervectorz;


uniform float rotatex_particle;
uniform float rotatey_particle;
uniform float rotatez_particle;

uniform float tempo_dt;
uniform float tempo_delta;
uniform float tempo_syncro;
uniform float syncro;

uniform float particles_separation;

uniform float dfacx;
float dfac = 5.0;
float w = dest_tex_size.x;
float h = dest_tex_size.y;
int max_scale_iterations = int( log2(w) );
int max_generations = max_scale_iterations * 2;
float incremento_generacion = 1.0f / float(max_generations); /*2^8.0 = 16*16 = 256 particulas en la 8va generacion*/
///float incremento_madurez = 0.04f;
float madurez_reproductiva = 1.0f - incremento_madurez;//esto es un criterio... podria ser 0.8.. 1.0f muere!
float LEFTSTATE = 0.3f;
float RIGHTSTATE = 0.9f;
/*
float left_rep_maturity = madurez_reproductiva;
float right_rep_maturity = madurez_reproductiva;
*/
struct ParticleState {
	float generation; /* src_state.x: [0.0f .. 1.0f]  step: (1.0f / K) = (1.0f / max_generations) */
	float division_age; /* src_state.y: [0.0f .. 1.0f] step: no-step */
	float age;  /* src_state.z: [0.0f .. 1.0f] step: 0.005f > must be time or tempo related */
	float origin;  /* src_state.w: [0..1] father generation > full age = (generation - origin) * K + age  */
} PState;



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


vec4 SetParticleNormal( vec4 father_normal ) {
  vec4 normal;
  float alpha;
  float phi;
  float radius;


  if (emittertype==5) {

  ///TRACKER > use for KINECT texture
    normal = vec4 ( father_normal.x,
                   father_normal.y,
                   father_normal.z,
                   0.83 );
	} else if (emittertype==7) {
		//SPIRAL
		vec2 TCoord = gl_TexCoord[0].st;
    int i = int( floor( TCoord.s * w ) );
    int j = int( floor( TCoord.t * h ) );
    float a_ij =  TCoord.s*(1.0+particles_separation);
    float a_ij2 =  float( i + j * w ) / float( w * h ) ;
		alpha = 2 * 3.1415 * ( a_ij );
		normal = vec4 ( 0,
                   0,
                   (alpha+3.1415/2)*180/3.1415,
                   0.83 );

  } else {
		normal = vec4 ( father_normal.x,
                   father_normal.y,
                   father_normal.z,
                   0.83 );
  }
  return normal;
}

void main(void)
{
    ParticleState State, Father;

    vec2 TCoord = gl_TexCoord[0].st;
    int i = int( floor( TCoord.s * w ) );
    int j = int( floor( TCoord.t * h ) );

    float i_to_s = float(i) / w;
    float j_to_t = float(j) / h;

    /// tomamos el vector posicion del padre (ip, jp, escala)
    vec3 father_indexes = whereIsMyFather( i, j, 0 );
    int ip = int(father_indexes.x);
    int jp = int(father_indexes.y);
    float scale = father_indexes.z;

    /// tomamos esta misma posicion en formato normalizado 0..1, 0..1
    vec2 father_tcoord;
    father_tcoord.s = father_indexes.x / w ;
    father_tcoord.t = father_indexes.y / h ;

    vec4 src_state = texture2D(src_tex_unit0, TCoord);
		vec4 src_velocity = texture2D(src_tex_unit1, TCoord);
    vec4 src_position = texture2D(src_tex_unit2, TCoord);
		vec4 src_normal = texture2D(src_tex_unit3, TCoord);
    vec4 father_normal = texture2D(src_tex_unit3, father_tcoord.st);
		vec4 src_scale = texture2D(src_tex_unit4, TCoord);

    State.generation = src_state.x;
    State.division_age = src_state.y;
    State.age = src_state.z;
    State.origin = src_state.w;


    vec2 TCoordMedium = vec2( (src_normal.x-6.0)/12.0, -(src_normal.y-6.0)/12.0 );
    if (tempo_angle.x<6.0) TCoordMedium = vec2( 0.0, 0.0 );
    vec4 medium = texture2D(src_tex_unit4, TCoordMedium );
    float zdepth = medium.z*(1.0-dfac);


    if ( tempo_angle.x == 0.0 ) {
      gl_FragColor = vec4( 0.0, 0.0, 0.0, 1.0);
    } else
    if (State.age >= incremento_madurez ) {

        if (  State.age==incremento_madurez ) {
          if (State.origin==LEFTSTATE) {

            gl_FragColor = SetParticleNormal( father_normal );

          } else if (State.origin==RIGHTSTATE) {
            gl_FragColor = vec4(
                              src_normal.x,
                              src_normal.y,
                              src_normal.z,
                              0.9 );
          }
        } else {

          gl_FragColor = vec4(
                            src_normal.x,
                            src_normal.y,
                            src_normal.z,
                            State.origin );
        }

				float tfi = 1.0 / w;
				float tfj = 1.0 / h;

				vec4 src_position0 = texture2D( src_tex_unit2, vec2( TCoord.s, TCoord.t ) );
				vec4 src_position1 = texture2D( src_tex_unit2, vec2( TCoord.s+tfi, TCoord.t ) );
				vec4 src_position2 = texture2D( src_tex_unit2, vec2( TCoord.s-tfi, TCoord.t ) );
				vec4 src_position3 = texture2D( src_tex_unit2, vec2( TCoord.s, TCoord.t-tfj ) );
				vec4 src_position4 = texture2D( src_tex_unit2, vec2( TCoord.s, TCoord.t+tfj ) );

				vec4 vXA = src_position1 - src_position0;
				vXA.z = vXA.z;
				vec4 vXB = src_position2 - src_position0;
				vXB.z = vXB.z;
				vec4 vYA = src_position3 - src_position0;
				vYA.z = vYA.z;
				vec4 vYB = src_position4 - src_position0;
				vYB.z = vYB.z;

				vec3 vN0 = normalize( cross( vXB.xyz, vXA.xyz ) );
				vec3 vN1 = normalize( cross( vXA.xyz, vYB.xyz ) );
				vec3 vN2 = normalize( cross( vYB.xyz, vXB.xyz ) );
				vec3 vN3 = normalize( cross( vXB.xyz, vYB.xyz ) );
				vec3 vN = vN0+vN1+vN2+vN3;
				gl_FragColor = vec4( 0.25*vN.x, 0.25*vN.y, 0.25*vN.z, State.origin );

    } else gl_FragColor = vec4( src_normal.x, src_normal.y, src_normal.z, 0.0);



}
