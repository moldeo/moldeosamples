#version 120
#extension GL_EXT_gpu_shader4 : enable

uniform sampler2D src_tex_unit0;// state
uniform sampler2D src_tex_unit1;// velocity
uniform sampler2D src_tex_unit2;// position
uniform sampler2D src_tex_unit3;// geneti
uniform sampler2D src_tex_unit4;// medium
uniform sampler2D src_tex_unit5;//altitude
uniform sampler2D src_tex_unit6;//variability
uniform sampler2D src_tex_unit7;//confidence
uniform vec2 src_tex_offset0;
uniform vec2 tempo_angle;
uniform vec2 dest_tex_size;
uniform vec2 random_uniform;

uniform float incremento_madurez;

uniform int maxage;
uniform int emitionperiod;
uniform int emitionrate;
uniform int randommethod;
uniform int creationmethod;

uniform int emittertype;
uniform float emittervectorx;
uniform float emittervectory;
uniform float emittervectorz;
uniform float randompositionx;
uniform float randompositiony;
uniform float randompositionz;

uniform float tempo_dt;
uniform float tempo_delta;
uniform float tempo_syncro;
uniform float syncro;

uniform float dfacx;
uniform float doffx;
uniform float dinversex;
uniform float doffinx;
float dfac = 0.0;
float doff = 0.0;
float doffin = 0.0;
float dinverse = 1.0;
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

int idx,jdx;
vec2 TCoord;

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


vec4 SetParticlePosition( vec4 father_position ) {
  vec4 pos3d;
  float alpha;
  float phi;
  float radius;
  if (emittertype==0 || emittertype==5 || emittertype==6) {
    ///GRID
		vec4 medium = texture2D(src_tex_unit4, TCoord );
    float zdepth = doff+(medium.z*dinverse-doffin)*dfac;
    pos3d = vec4(        (TCoord.s-0.5)*12.0f*emittervectorx,
                                (TCoord.t-0.5)*12.0f*emittervectory,
                                zdepth*0.03,
                                0.83f );
	} else if (emittertype==1) {
	///SPHERE
	/**
	alpha = 2 * moMathf::PI * pParticle->Pos.X() / (double)m_cols;
	phi = moMathf::PI * pParticle->Pos.Y() / (double)m_rows;
	radius = moMathf::Sqrt( m_Physics.m_EmitterSize.X()*m_Physics.m_EmitterSize.X()+m_Physics.m_EmitterSize.Y()*m_Physics.m_EmitterSize.Y()) / 2.0;

	pParticle->Pos3d = moVector3f(  (radius*moMathf::Cos(alpha)*moMathf::Sin(phi) + randomposx ) * m_Physics.m_EmitterVector.X(),
														(radius*moMathf::Sin(alpha)*moMathf::Sin(phi) + randomposy ) * m_Physics.m_EmitterVector.Y(),
														(radius*moMathf::Cos(phi) + randomposz ) * m_Physics.m_EmitterVector.Z() );
	*/
	vec4 medium = texture2D(src_tex_unit4, TCoord );
	float zdepth = doff+(medium.z*dinverse-doffin)*dfac;

	alpha = 2 * 3.1415f * TCoord.s;
	phi = 3.1415f * TCoord.t;
	radius = sqrt(emittervectorx*emittervectorx + emittervectory*emittervectory+emittervectorz*emittervectorz);
	if (!(idx==0 || idx==(w-1)) ) radius = radius + zdepth;
	pos3d = vec4(        radius*cos(alpha)*sin(phi)*emittervectorx,
												radius*sin(alpha)*sin(phi)*emittervectory,
												radius*cos(phi)*emittervectorz,
												0.83f );
  } else if (emittertype==2) {
    ///TUBE
/**
alpha = 2 * moMathf::PI * pParticle->Pos.X() / (double)m_cols;
                    radius1 = m_Physics.m_EmitterSize.X() / 2.0;
                    radius2 = m_Physics.m_EmitterSize.Y() / 2.0;
                    z = m_Physics.m_EmitterSize.Z() * ( 0.5f - ( pParticle->Pos.Y() / (double)m_rows ) );

                    pParticle->Pos3d = moVector3f(  ( radius1*moMathf::Cos(alpha) + randomposx ) * m_Physics.m_EmitterVector.X(),
                                                    ( radius1*moMathf::Sin(alpha) + randomposy ) * m_Physics.m_EmitterVector.Y(),
                                                    ( z + randomposz ) * m_Physics.m_EmitterVector.Z() );
*/

		vec4 medium = texture2D(src_tex_unit4, TCoord );
		float zdepth = doff+(medium.z*dinverse-doffin)*dfac;

    alpha = 2 * 3.1415 * TCoord.s;
    float radius1 = (emittervectorx / 2.0) + zdepth;
    float radius2 = (emittervectory / 2.0) + zdepth;
		float z = emittervectorz * ( 0.5 - ( TCoord.t ) );

    pos3d = vec4(        radius1*cos(alpha)*emittervectorx,
                         radius2*sin(alpha)*emittervectory,
                         z*emittervectorz,
                                0.83f );

  } else if (emittertype==4) {
    ///POINT: toma la posicion del padre...
    pos3d = vec4 ( father_position.x,
                    father_position.y,
                    father_position.z,
                    0.83 );
  /*
	} else if (emittertype==5) {
  ///TRACKER > use for KINECT texture
    vec2 TCoordMedium = vec2( (father_position.x-6.0)/12.0f, -(father_position.y-6.0)/12.0f );
    if (tempo_angle.x<6.0f) TCoordMedium = vec2( 0.0f, 0.0f );
    vec4 medium = texture2D(src_tex_unit4, TCoordMedium );
    float zdepth = doff+medium.z*dfac;
    pos3d = vec4 ( father_position.x,
                   father_position.y,
                   zdepth,
                   0.83 );
    } else if (emittertype==6) {
  ///TRACKER > use for KINECT texture
    vec2 TCoordMedium = vec2( (father_position.x-6.0)/12.0f, -(father_position.y-6.0)/12.0f );
    if (tempo_angle.x<6.0f) TCoordMedium = vec2( 0.0f, 0.0f );
    vec4 medium = texture2D(src_tex_unit4, TCoordMedium );
    float zdepth = doff+medium.z*dfac;
    if (medium.z!=0) {
    pos3d = vec4 ( father_position.x,
                   father_position.y,
                   zdepth,
                   0.83 );
    }
		else {
        pos3d = vec4 ( father_position.x,
                   father_position.y,
                   1000000.0,
                   0.83 );

    }*/
  } else {
		//toma la posicin del padre
    pos3d = vec4 ( father_position.x,
    father_position.y,
    father_position.z,
    0.83 );

  }
  return pos3d;
}

void main(void)
{
    ParticleState State, Father;

    TCoord = gl_TexCoord[0].st;
    idx = int( floor( TCoord.s * w ) );
    jdx = int( floor( TCoord.t * h ) );

    float i_to_s = float(idx) / w;
    float j_to_t = float(jdx) / h;

    /// tomamos el vector posicion del padre (ip, jp, escala)
    vec3 father_indexes = whereIsMyFather( idx, jdx, 0 );
    int ip = int(father_indexes.x);
    int jp = int(father_indexes.y);
    float scale = father_indexes.z;
    dfac = dfacx;
    doff = doffx;
		doffin = doffinx;
		dinverse = dinversex;

    /// tomamos esta misma posicion en formato normalizado 0..1, 0..1
    vec2 father_tcoord;
    father_tcoord.s = father_indexes.x / w ;
    father_tcoord.t = father_indexes.y / h ;

    vec4 src_state = texture2D(src_tex_unit0, gl_TexCoord[0].st);
    vec4 src_velocity = texture2D(src_tex_unit1, gl_TexCoord[0].st);
    vec4 src_position = texture2D(src_tex_unit2, gl_TexCoord[0].st);
    vec4 father_position = texture2D(src_tex_unit2, father_tcoord.st);

    State.generation = src_state.x;
    State.division_age = src_state.y;
    State.age = src_state.z;
    State.origin = src_state.w;

    vec2 TCoordMedium = vec2( (src_position.x-6.0)/12.0f, -(src_position.y-6.0)/12.0f );
    if (tempo_angle.x<6.0f) TCoordMedium = vec2( 0.0f, 0.0f );
    vec4 medium = texture2D(src_tex_unit4, TCoordMedium );
    float zdepth = doff+(medium.z*dinverse-doffin)*dfac;


/** //For debugging

if ( tempo_angle.x == 0.0f ) {
    gl_FragColor = vec4( 0.0f, 0.0f, 0.0f, 0.0f);
}
gl_FragColor = vec4( 0.0f, 0.0f, 0.0f, 1.0f);
*/

	//src_color = vec4( gl_TexCoord[0].s-0.5, gl_TexCoord[0].t-0.5, 0.0f, 1.0f );
    if ( tempo_angle.x == 0.0f ) {
      gl_FragColor = vec4( 0.0f, 0.0f, 0.0f, 0.0f);
    } else
    if (State.age >= incremento_madurez ) {
/**
      if (emittertype==5 && medium.z!=0.0) {
        src_position.z = zdepth;
      }
      if (emittertype==6) {
        if (medium.z!=0.0) {
            src_position.z = zdepth;
        } else {
            src_position.z = 0.0;
        }
      }*/

        if (  State.age==incremento_madurez ) {
          if (State.origin==LEFTSTATE) {
            gl_FragColor = SetParticlePosition( father_position );
            /**
           gl_FragColor = vec4 ( father_position.x,
                    father_position.y,
                    father_position.z,
                    0.83 );
                    */
          } else if (State.origin==RIGHTSTATE) {
            gl_FragColor = vec4(
                              src_position.x,
                              src_position.y,
                              src_position.z,
                              0.9 );
          }
        } else {

					if ( emittertype==1 || emittertype==2) {
						src_position = SetParticlePosition( father_position );
					}

          float fz = src_position.z + src_velocity.z*tempo_delta*tempo_syncro*syncro;

          if ( (emittertype==5 || emittertype==6) /*&& medium.z!=0.0*/ ) {
						if (medium.z!=0.0) {
							fz = zdepth;
						} else {
							fz = 0.0;
						}
          }
          gl_FragColor = vec4(
                            src_position.x + src_velocity.x*tempo_delta*tempo_syncro*syncro,
                            src_position.y + src_velocity.y*tempo_delta*tempo_syncro*syncro,
                            fz,
                            State.origin );
        }
    } else gl_FragColor = vec4( src_position.x, src_position.y, src_position.z, 0.0f);



}
