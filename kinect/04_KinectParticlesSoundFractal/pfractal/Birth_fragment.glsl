#version 120
#extension GL_EXT_gpu_shader4 : enable

/**

	Particles = NxN
	N = 2^n = dest_tex_size.x
		condition: dest_tex_size.x = dest_tex_size.y !!!

	max_scale_iterations = 	n
	max_generations = 		K = 2n

	range: Scale [0..(n-1)]



*/

uniform sampler2D src_tex_unit0;
uniform vec2 src_tex_offset0;
uniform vec2 tempo_angle;
uniform vec2 dest_tex_size;
uniform vec2 random_uniform;

struct Rule {
	float	speed_min; /** */
	float	speed_max;
	float	shapeScale; /** */
	float	angle_min; /** */
	float	angle_max; /** */
	float	reproduction_time; /** 0..1.0f   0: no reproduction 1.0:  */
	float	timeScale;
};

struct ParticleState {
	float generation; /* src_state.x: [0.0f .. 1.0f]  step: (1.0f / K) = (1.0f / max_generations) */
	float division_age; /* src_state.y: [0.0f .. 1.0f] step: no-step */
	float age;  /* src_state.z: [0.0f .. 1.0f] step: 0.005f > must be time or tempo related */
	float origin;  /* src_state.w: [0..1] father generation > full age = (generation - origin) * 2 * max_scale_iterations + age  */
} PState;

uniform float incremento_madurez;



float w = dest_tex_size.x;
float h = dest_tex_size.y;
int max_scale_iterations = int( log2(w) );
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

	i = posición de la columna
	j = posición de la fila
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


/**
	TRUE IF generation and scale are related...
	this function decide WHEN is the right moment for a particle to be born by his father...
	it depends on relative position, scale and generation of his father.


	GenSon = generation of the father -> incremented -> generation of the son
	range: GenSon [0..K]

	HORIZONTAL condition: j==jp &&  (GenFather+1)/2 + Scale = n - 1
	VERTICAL condition: (GenFather+1)/2 + Scale = n

*/
bool reproduction_condition(	float p_father_generation,
								float p_father_maturity,
								float p_father_mat_reproduction,
								float p_son_scale,
								int i, int j,
								int ip, int jp ) {

	if ( 	p_father_maturity==0.0f
			|| p_father_maturity < p_father_mat_reproduction
			|| p_father_mat_reproduction==0.0f )
		return false;

	int GenSon = int(p_father_generation*float(max_generations) + 1);
	int GenSonMod2 = GenSon & 1;
	int GenSonDiv2 = GenSon / 2;
	int Scale = int(p_son_scale);
	int n_minus_1 = max_scale_iterations - 1;
	int n_raw = max_scale_iterations;

	if ( j==jp && GenSonMod2==1 /*odd generations*/ ) {

		//HORIZONTAL REPRODUCTION
		if ( ( GenSonDiv2 + Scale ) == n_minus_1 ) {
			//OK TO BE BORN!!
			return true;
		}

	} else if ( i==ip && GenSonMod2==0 /*even generations*/ ) {
		//VERTICAL REPRODUCTION
		//(always after HORIZONTAL REPRODUCTION > use n_raw = n_minus_1 + 1)
		if ( ( GenSonDiv2 + Scale ) == n_raw ) {
			//OK TO BE BORN!!
			return true;
		}
	}

	//NOT OUR GENERATION TIME....
	return false;

}

void main(void)
{
  ParticleState State, Father;

  vec4 src_state = texture2D( src_tex_unit0, gl_TexCoord[0].st );
	vec2 TCoord = gl_TexCoord[0].st;

  State.generation = src_state.x;
  State.division_age = src_state.y;
  State.age = src_state.z;
  State.origin = src_state.w;

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

  /// tomamos esta misma posicion en formato normalizado 0..1, 0..1
	vec4 father_state = texture2D(src_tex_unit0, father_tcoord );
	int father_generation = int(father_state.x);
	int fathergen_mod_2 = father_generation & 1;
	int this_generation = int(src_state.x);
	int thisgen_mod_2 = this_generation & 1;

  Father.generation = father_state.x;
  Father.division_age = father_state.y;
  Father.age = father_state.z;
  Father.origin = father_state.w;

  madurez_reproductiva = 1.0f - incremento_madurez;//esto es un criterio... podria ser 0.8.. 1.0f muere!
  left_rep_maturity = madurez_reproductiva;
  right_rep_maturity = madurez_reproductiva;


  if (tempo_angle.x == 0.0f) {
    gl_FragColor = vec4(	0.0f, 0.0f, 0.0f, 0.0f );
  } else

	/**
		CELULA MADRE
	*/
	if ( i==0 && j==0 ) {

		if ( State.age/*madurez*/ == 0.0f
      && State.generation/*generacion*/ == 0.0f ) {

			/** NACIMIENTO: BIG BANG*/
			///generacion 0 !!! ORIGINAL BIRTH (CELULA MADRE)

			gl_FragColor = vec4(	0.0 /*generacion*/,
                            left_rep_maturity,
                            incremento_madurez /*madurez*/,
                            ST_BORN );

		} else if ( State.age>= incremento_madurez
					&&
					State.age < madurez_reproductiva /*src_state.y*/ /*madurez de reproducción*/ ) {

			/** MADURACION , MIGRACION, INTERACCIONES.... */

			gl_FragColor = vec4( 	State.generation /*generacion*/,
                            State.division_age /*src_state.y*/ /*madurez para la reproduccion*/,
                            State.age + incremento_madurez /*madurez*/,
                            State.origin );

		} else if ( State.age /*madurez*/ >= madurez_reproductiva /*src_state.y*/ /*madurez de reproducción*/ ) {

			/** REPRODUCCION (CELULA MADRE) */

			//esta particula se reproduce (y continua hacia su nuevo ciclo de reproducción)
			gl_FragColor = vec4(	State.generation + incremento_generacion /*generacion*/,
                            right_rep_maturity,
                            incremento_madurez /*madurez*/,
                            ST_RECYCLE );

		} else {
			gl_FragColor = src_state;
			//gl_FragColor = vec4( src_state.x, src_state.y, src_state.z , 1.0);
		}

	/**

	HIJOS DE LA CELULA MADRE


	*/
	} else {
		//gl_FragColor = vec4( 0.0f, 0.0f, src_state.z + 0.005f, 1.0f );
		if ( State.age == 0.0f /*nonato*/
			 && reproduction_condition( 	Father.generation /*father generation*/,
											Father.age /*father maturity*/,
											Father.division_age /*madurez_reproductiva*/,
											scale /*scale to reach father*/, i,j,ip,jp ) ) {

			/** NACIMIENTO (regla izquierda) */
			gl_FragColor = vec4(	Father.generation + incremento_generacion /*generacion: la generacion de una hija siempre es superior a la del padre*/,
									left_rep_maturity /*RuleRightDefault_reproduction_time*/ /*madurez de reproducción: siempre se aplica la REGLA DERECHA cuando nace, izquierda cuando se auto-reproduce*/,
									incremento_madurez /*madurez*/,
									ST_BORN );

		} else if ( State.age >= incremento_madurez /*madurando: vivo y coleando*/
					&&
					State.age < madurez_reproductiva ) {

			/** MADURACION , MIGRACION, INTERACCIONES.... */
			gl_FragColor = vec4( 	State.generation /*generacion*/,
									State.division_age /*src_state.y*/ /*madurez de reproducción*/,
									State.age + incremento_madurez /*madurez*/,
									State.origin );

		} else if (
					State.age >= madurez_reproductiva /*src_state.y > AUTOREPRODUCCION*/ /*madurez de reproducción*/ ) {

			/** REPRODUCCION (regla derecha) > RENACIMIENTO?*/
			//esta particula se reproduce (y continua hacia su nuevo ciclo de reproducción)
			float nextgen = State.generation + incremento_generacion;
/*
			if (nextgen>1.0f) {
        nextgen = 1.0f;
			}
*/
			gl_FragColor = vec4( 	 nextgen/*generacion*/,
									right_rep_maturity /*RuleLeftDefault_reproduction_time*/ /*madurez de reproducción: inicial, siempre se aplica la REGLA IZQUIERDA cuando es auto-reproducción*/,
									incremento_madurez /*madurez*/,
									ST_RECYCLE );

		} else {
			gl_FragColor = src_state;
			//gl_FragColor = vec4( src_state.x, src_state.y, src_state.z , 1.0);
		}
	}


}
