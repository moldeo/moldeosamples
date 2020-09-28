#version 120
#extension GL_EXT_gpu_shader4 : enable

uniform sampler2D src_tex_unit0;// state
uniform sampler2D src_tex_unit1;// genetic
uniform sampler2D src_tex_unit2;// velocity
uniform sampler2D src_tex_unit3;// position
uniform sampler2D src_tex_unit4;// medium
uniform sampler2D src_tex_unit5;// altitude
uniform sampler2D src_tex_unit6;// variability
uniform sampler2D src_tex_unit7;// confidence
uniform vec2 src_tex_offset0;
uniform vec2 tempo_angle;
uniform vec2 dest_tex_size;
uniform vec2 random_uniform;
uniform float fade_const;
float PI = 3.14159265358979323846264;

uniform float incremento_madurez;
uniform float gravity;
uniform float viscosity;
uniform float attractorvectorx;
uniform float attractorvectory;
uniform float attractorvectorz;
uniform int attractortype;
uniform int attractormode;

uniform float randomvelocity;
uniform float randomvelocityx;
uniform float randomvelocityy;
uniform float randomvelocityz;

uniform float randommotion;
uniform float randommotionx;
uniform float randommotiony;
uniform float randommotionz;

uniform float tempo_dt;
uniform float tempo_delta;
uniform float tempo_syncro;
uniform float syncro;

float td2;

int LFSR_Rand_Gen(in int n)
{
  // <<, ^ and & require GL_EXT_gpu_shader4.
  n = (n << 13) ^ n;
  return (n * (n*n*15731+789221) + 1376312589) & 0x7fffffff;
}

float LFSR_Rand_Gen_f( in int n )
{
  return float(LFSR_Rand_Gen(n));
}

float rand(vec2 co){
  return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.54537256);
}

float randt() {
  return rand(tempo_angle);
}

float noise3f(in vec3 p)
{
  ivec3 ip = ivec3(floor(p));
  vec3 u = fract(p);
  u = u*u*(3.0-2.0*u);

  int n = ip.x + ip.y*57 + ip.z*113;

  float res = mix(mix(mix(LFSR_Rand_Gen_f(n+(0+57*0+113*0)),
                          LFSR_Rand_Gen_f(n+(1+57*0+113*0)),u.x),
                      mix(LFSR_Rand_Gen_f(n+(0+57*1+113*0)),
                          LFSR_Rand_Gen_f(n+(1+57*1+113*0)),u.x),u.y),
                 mix(mix(LFSR_Rand_Gen_f(n+(0+57*0+113*1)),
                          LFSR_Rand_Gen_f(n+(1+57*0+113*1)),u.x),
                      mix(LFSR_Rand_Gen_f(n+(0+57*1+113*1)),
                          LFSR_Rand_Gen_f(n+(1+57*1+113*1)),u.x),u.y),u.z);

  return 1.0 - res*(1.0/1073741824.0);
}


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
	float generation; /* src_color.x: [0.0f .. 1.0f]  step: (1.0f / K) = (1.0f / max_generations) */
	float maturity_reproduction; /* src_color.y: [0.0f .. 1.0f] step: no-step */
	float maturity_cycle;  /* src_color.z: [0.0f .. 1.0f] step: 0.005f > must be time or tempo related */
	float origin;  /* src_color.w: [0..1] father generation > age = (generation - origin) * K + maturity_cycle   */
};

float w = dest_tex_size.x;
float h = dest_tex_size.y;
int max_scale_iterations = int( log2(w) );
int max_generations = max_scale_iterations * 2;
float incremento_generacion = 1.0f / float(max_generations); /*2^8.0 = 16*16 = 256 particulas en la 8va generacion*/
///float incremento_madurez = 0.04f;
float madurez_reproductiva = 1.0f - incremento_madurez;

float LEFTSTATE = 0.3f;
float RIGHTSTATE = 0.9f;

float ST_BORN = 0.3f;
float ST_RECYCLE = 0.9f;
/*
float left_rep_maturity = madurez_reproductiva;
float right_rep_maturity = madurez_reproductiva;
*/

/**
float left_rep_angle_min = 2*PI/3.0f; //src_genetic.x
float left_rep_angle_max = 2*PI/3.0f; //src_genetic.y

float right_rep_angle_min = 2*PI/3.0f; //src_genetic.y
float right_rep_angle_max = 2*PI/3.0f; //src_genetic.z

float left_mov_angle_min = -0.1f;
float left_mov_angle_max = 0.1f;

float right_mov_angle_min = -0.1f;
float right_mov_angle_max = 0.1f;
*/
uniform float left_rep_angle_min;
uniform float left_rep_angle_max;

uniform float right_rep_angle_min;
uniform float right_rep_angle_max;

uniform float left_mov_angle_min;
uniform float left_mov_angle_max;

uniform float right_mov_angle_min;
uniform float right_mov_angle_max;


vec4 initial_velocity =         vec4( 0.0f, 0.008f, 0.0f, 1.0f );
vec4 initial_reborn_velocity =  vec4( -1.0f, -1.0f, 0.0f, 1.0f );




vec4 FormulaVelocity( vec4 src_position, vec4 father_velocity, vec4 src_velocity, vec4 src_state, int i, int j, int repro ) {

  float vx = src_velocity.x;
  float vy = src_velocity.y;
  float vz = src_velocity.z;

  if (repro==1) vx = father_velocity.x;
  if (repro==1) vy = father_velocity.y;
  if (repro==1) vz = father_velocity.z;


  if ((src_position.x+vx)>6.0f) {
    vx = -vx;
  }
  if ((src_position.y+vy)>6.0f) {
    vy = -vy;
  }
    if ((src_position.x+vx)<-6.0f) {
    vx = -vx;
  }
  if ((src_position.y+vy)<-6.0f) {
    vy = -vy;
  }
    if ((src_position.z+vz)<-6.0f) {
    vz = -vz;
  }
  if ((src_position.z+vz)>6.0f) {
    vz = -vz;
  }
/**
  vec2 TCoordMedium = vec2( (src_position.x-6.0)/12.0f, -(src_position.y-6.0)/12.0f );
  vec2 TCoordMedium2 = vec2( (src_position.x+vx-6.0)/12.0f, -(src_position.y+vy-6.0)/12.0f );
  if (tempo_angle.x<6.0f) TCoordMedium = vec2( 0.0f, 0.0f );
  if (tempo_angle.x<6.0f) TCoordMedium2 = vec2( 0.0f, 0.0f );
	vec4 medium = texture2D(src_tex_unit4, TCoordMedium );
	vec4 medium2 = texture2D(src_tex_unit4, TCoordMedium2 );
	vec4 difmedium = medium2-medium;
*/
  float vnorma = sqrt( vx*vx+vy*vy+vz*vz );
  float thresh = 0.3f;
  float maxv = 4.3f;
///FRENA SI VA MUY RAPIDO
  while ( vnorma > maxv ) {
    vx = vx*0.9f;
    vy = vy*0.9f;
    vz = vz*0.9f;
    vnorma = sqrt( vx*vx+vy*vy+vz*vz );
  }
/*
	/// si va de oscuro a claro, retrocede
  if ( (medium.r<0.4f && medium.g<0.4f && medium.b<0.4f )
        && (medium2.r>0.4f || medium2.g>0.4f || medium2.b>0.4f) ) {
    vx = -vx;
    vy = -vy;
  }

  if ( (medium.r>0.4f && medium.g>0.4f && medium.b>0.4f )
        && (medium2.r>0.4f || medium2.g>0.4f || medium2.b>0.4f) ) {
    vec2 maxspeed = normalize(vec2(vx,vy))*maxv;
    vx = maxspeed.x;
    vy = maxspeed.y;
  }*/
/**
  /// si es un color mas o menos claro, rodeado de otros colores parecidos, acelera (para salirse)
  if ( (medium.r>=0.1f || medium.g>=0.1f || medium.b>=0.1f ) ) {
    vx = vx*(1.0f + 0.001f);
    vy = vy*(1.0f + 0.001f);
  }
*/
  float vteta = 0.0f;

  float rdivide = 1.0f;
  float rmotion = 1.0f;

  //rmotion = 0.5f*( 1.0f + cos(tempo_angle.x*117+tempo_angle.y*7+i*1241-j*2123+father_velocity.x*7943) );
  //rmotion = 0.5f*( 1.0f + cos(tempo_angle.x*1117+tempo_angle.y*223+i-j+father_velocity.x+father_velocity.y) );
  //rmotion = random_uniform.x;


  rmotion = 0.5f*( 1.0f + cos( i*fract(random_uniform.x)-j*fract(random_uniform.x*1000.0f)) );
  //rmotion = 0.5f;

/*
  if (vx!=0 && vy>=0) {
    vteta = acos( vx / vnorma );
  } else if (vx!=0 && vy<0) {
    vteta = asin( vy / vnorma );
    if (vx>0) {
       vteta = 2*PI + vteta;
    } else if (vx<0) {
       vteta = PI - vteta;
    }
  } else if (vx==0) {
    if (vy<0) {
      vteta = 1.5*PI;
    } else {
      vteta = 0.5*PI;
    }
  }
*/
  if (vx==0.0f) {
    if (vy<0.0f) {
      vteta = 1.5f*PI;
    } else {
      vteta = 0.5f*PI;
    }
  } else if (vy==0.0f) {
    if (vx<0.0f) {
      vteta = PI;
    } else {
      vteta = 0.0f;
    }
  } else if ( abs(vx) > abs(vy) ) {
    vteta = acos( vx / vnorma );
    if (vy<0.0f) {
      vteta = -vteta;
    }
  } else {
    vteta = asin( vy / vnorma );
    if (vx<0.0f) {
      vteta = PI - vteta;
    }
  }
/*
if (vx==0.0) then
				if ( dif>0 and i==0) then
					--this:PushDebugString("VX==0? vteta:"..vteta.." vx:"..vx.." vy:"..vy.." vnorma:"..vnorma);
				end
				if (vy<0.0) then
					vteta = 1.5*math.pi
				else
					vteta = 0.5*math.pi
				end
			elseif (vy==0.0) then
				if ( dif>0 and i==0) then
					--this:PushDebugString("VY==0? vteta:"..vteta.." vx:"..vx.." vy:"..vy.." vnorma:"..vnorma);
				end
				if (vx<0.0) then
					vteta = math.pi
				else
					vteta = 0.0
				end
			elseif (math.abs(vx)>math.abs(vy)) then
				vteta = math.acos( vx / vnorma )
				if ( dif>0 and i==0) then
					--this:PushDebugString("|VX|>|VY|? vteta:"..vteta.." vx:"..vx.." vy:"..vy.." vnorma:"..vnorma);
				end
				if (vy<0.0) then
					vteta = - vteta
				end
			else
				vteta = math.asin( vy / vnorma )
				if ( vx<0.0) then
					vteta = math.pi - vteta
				end
			end
*/



  /** FIRST BORN left rule*/
  if (src_state.w==ST_BORN) {

    //if (repro) vteta = vteta  + left_rep_angle_min;

    if (repro>=1) vteta = vteta + left_rep_angle_min + (left_rep_angle_max - left_rep_angle_min)*rdivide;//nuevo angulo agregado
    else vteta = vteta + left_mov_angle_min + (left_mov_angle_max - left_mov_angle_min)*rmotion;//nuevo angulo agregado
    //else vteta = vteta -0.1f + 0.2f*( ) );
    //return initial_velocity/400.0f;
    //return father_velocity+initial_velocity;
    //return initial_velocity+ vec4( 2.0 - 4.0*noise3f(src_velocity.xyz), 2.0 - 4.0*noise3f(father_velocity.xyz), 0.0f, 1.0f);
    //return father_velocity+vec2(-i*0.01,j*0.02);
    //return vec4( initial_velocity.x/src_state.x, initial_velocity.y/src_state.x, initial_velocity.z/src_state.x, 1.0f);
    //return vec4( father_velocity.x/1.618f, father_velocity.y/1.618f, father_velocity.z/1.618f, 1.0f);
  /** RE BORN right rule*/
  } else if (src_state.w==ST_RECYCLE) {
//    if (repro) vteta = vteta  - right_rep_angle_min;

    if (repro>=1) vteta = vteta  - right_rep_angle_min - (right_rep_angle_max - right_rep_angle_min)*rdivide;//nuevo angulo agregado
    else vteta = vteta + right_mov_angle_min + (right_mov_angle_max - right_mov_angle_min)*rmotion;//nuevo angulo agregado
    //return initial_reborn_velocity/400.0f;
    //return father_velocity+initial_reborn_velocity;
    // return initial_reborn_velocity+ vec4( 2.0 - 4.0*noise3f(father_velocity.xyz), 2.0 - 4.0*noise3f(src_velocity.xyz), 0.0f, 1.0f);
    //return father_velocity+vec2(i*0.021,-j*0.031);
    //return vec4( initial_reborn_velocity.x/src_state.x, initial_reborn_velocity.y/src_state.x, initial_reborn_velocity.z/src_state.x, 1.0f);
    //return vec4( -father_velocity.x/1.618f, father_velocity.y/1.618f, father_velocity.z/1.618f, 1.0f);
  }

  if (vz==0.0) {
    vx = vnorma * cos(vteta);
    vy = vnorma * sin(vteta);
  }



/*
			if (g_calculations>0) then
				angle_new = math.random( 0,1000) * 0.001 * ( grupo["angle_1"] - grupo["angle_0"] )
				grupo["angle_new"] = 3.141516 * ( angle_new + grupo["angle_0"] )
			end
*/


	//return vec4( 1.0f, 1.0f, 1.0f, 1.0f);
	return vec4( vx,vy, vz, 1.0f);;

}

vec4 FormulaForces( vec4 p_position, vec4 p_velocity, float p_gravity, float p_viscosity, int p_type, int p_mode, vec3 p_attractor ) {

  vec4 d_velocity;

  td2 = tempo_delta*tempo_syncro*syncro;
  td2 = 1.0;

  if (p_type==4) {
  ///JET
  /*
  if (medium.b>0.5f && medium.r>0.5f)
        dst_velocity = vec4( src_velocity.x*0.0f, src_velocity.y*0.0f, src_velocity.z*0.0f, 1.0f );
    */
    float dot1 = dot( p_attractor, p_position.xyz );
    float det = length(p_attractor);
    float mu = 0.0;
    if (det>0) {
        mu = dot1 / det;
    }
    d_velocity = p_gravity*( vec4(p_attractor*mu, 1.0 ) - p_position )*td2 -  p_velocity*p_viscosity*td2;

  } else if (p_type==0) {
    ///POINT
    d_velocity = p_gravity*( vec4(p_attractor, 0.0 ) - p_position )*td2 -  p_velocity*p_viscosity*td2;
  } else d_velocity = - p_velocity*p_viscosity*td2;


	return d_velocity;

}


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

	/*
		src_state.x : generation
		src_state.y : reproduction (receptive)
		src_state.z : maturity
		src_state.w : origin (generation)
	*/


void main(void)
{

	vec2 TCoord = gl_TexCoord[0].st;
	vec4 src_state = texture2D(src_tex_unit0, TCoord);
	vec4 src_genetic = texture2D(src_tex_unit1, TCoord);
	vec4 src_velocity = texture2D(src_tex_unit2, TCoord);
	vec4 src_position = texture2D(src_tex_unit3, TCoord);

	vec4 src_medium = texture2D(src_tex_unit4, TCoord);
	vec4 src_altitude = texture2D(src_tex_unit5, TCoord);
	vec4 src_variability = texture2D(src_tex_unit6, TCoord);
	vec4 src_confidence = texture2D(src_tex_unit7, TCoord);

  //vec2 TCoordMedium = vec2( 0.5f+(src_position.x/5.0f), 0.5f+ (src_position.y/5.0f) );
  //vec2 TCoordMedium = vec2( 0.5f+(src_position.x/5.0f), 0.5f+ (src_position.y/5.0f) );
  //vec2 TCoordMedium = vec2( ((6.0f-src_position.x)/12.0f), ((6.0f-src_position.y)/12.0f) );


	int i = int( floor( TCoord.s * w ) );
	int j = int( floor( TCoord.t * h ) );

	//vec4 src_force = texture2D(src_tex_unit2, gl_TexCoord[0].st);

	vec4 dst_velocity = src_velocity;
	vec4 father_src_velocity;

	bool src_state_alive = ( src_state.z >= incremento_madurez );
	bool src_state_dead = ( src_state.z == 0.0f );
	bool src_state_born = ( src_state.z == incremento_madurez  );
	bool src_velocity_inactive = ( src_velocity.w == 0.0f );
	bool src_velocity_active = !src_velocity_inactive;

    float rv = random_uniform.x;
    float runi = random_uniform.x*2*(random_uniform.x-0.5f);
    float rparti = rand( vec2(25.0f+random_uniform.x+i*27+j,11.0f+ tempo_angle.x+13*random_uniform.x));
    float rpartix = 0.5*cos(rparti*2*3.1416);
    float rpartiy = 0.5*sin(rparti*2*3.1416);
    //float rpartiz = 0.5*cos( rpartix - rpartiy)*sin(rpartix + rpartiy);
    float rpartiz = 0.5*cos(rpartix)*sin(rpartiy);

    if (src_variability.r>0.0) {
    }

	initial_velocity = vec4( randomvelocity*randomvelocityx,
                            randomvelocity*randomvelocityy,
                            randomvelocity*randomvelocityz,
                            1.0f );
    //initial_velocity = vec4(src_variability.rgb*0.1, 0.0f);
  ///gl_FragColor = vec4( 0.0f, 0.0f, 0.0f, 1.0f );

  if ( tempo_angle.x == 0.0f ) {
    dst_velocity = vec4(0.0f, 0.0f, 0.0f, 0.0f);
  } else
	/// Mother cell >
	if (i==0 && j==0 && src_velocity_inactive && src_state_born ) {

		dst_velocity = initial_velocity;//DEPENDE DE LA POSICION DE LOS PADRES!!!

  /// IS DEAD
	} else if ( src_state_dead )
	{
		dst_velocity.w = 0.0f;
	}
	/// IS ALIVE
	else if (src_state_alive)
	{
    /// JUSt BORN > define her initial velocity
		if ( src_state_born ) {

      int rep = 0;
      if (src_state.w == ST_RECYCLE ) {

          father_src_velocity = src_velocity;
          if ( src_state.x <= 1.0f ) rep = 1;

      } else if (src_state.w == ST_BORN ) {

        vec3 father_indexes = whereIsMyFather( i, j, 0 );

        int ip = int(father_indexes.x);
        int jp = int(father_indexes.y);
        float scale = father_indexes.z;

        vec2 father_tcoord;
        father_tcoord.s = father_indexes.x / w ;
        father_tcoord.t = father_indexes.y / h ;

        father_src_velocity = texture2D(src_tex_unit2, father_tcoord );
        rep = 1;
        //if ( src_state.x < 1.0f ) rep = 1;

      }

      dst_velocity = FormulaVelocity( src_position, father_src_velocity, src_velocity, src_state, i, j, rep );
      //dst_velocity = vec4( 1.0f, 1.0f, 1.0f, 1.0f );
      //dst_velocity = father_src_velocity;
    }
    /// MIGRATING: update her velocity
    else {//dst_velocity = FormulaForces( src_velocity, src_force );
      //gl_FragColor = dst_velocity;
      //dst_velocity = FormulaVelocity( father_src_velocity, src_velocity, src_force );
      vec4 src_force = vec4( 0.0, 0.0, 0.0, 0.0);
      src_force = FormulaForces( src_position, src_velocity, gravity, viscosity, attractortype, attractormode, vec3( attractorvectorx, attractorvectory, attractorvectorz) );
      dst_velocity = FormulaVelocity( src_position, src_velocity, src_velocity, src_state, i, j, 0 )
                    + 0.00001f*vec4( src_force.rgb, 0.0f )
                    + vec4( rpartix*randommotion*randommotionx,
                            rpartiy*randommotion*randommotiony,
                            rpartiz*randommotion*randommotionz, 0.0f)
                    ;

      dst_velocity = dst_velocity - dst_velocity*viscosity;

		}
	}


	gl_FragColor = dst_velocity;

}
