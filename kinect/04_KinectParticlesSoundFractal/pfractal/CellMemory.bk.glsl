#version 120
#extension GL_EXT_gpu_shader4 : enable

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


float w = dest_tex_size.x;
float h = dest_tex_size.y;

void main(void)
{

    int i = int( floor( gl_TexCoord[0].s * w ) );
    int j = int( floor( gl_TexCoord[0].t * h ) );

//    float rmotion = 0.5f*( 1.0f + cos( i*frac(random_uniform.x)-j*frac(random_uniform.x*1000.0f)) );

    vec4 src_cellcode = texture2D(src_tex_unit0, gl_TexCoord[0].st);
    vec4 src_cellmemory = texture2D(src_tex_unit1, gl_TexCoord[0].st);
    vec4 src_state = texture2D(src_tex_unit2, gl_TexCoord[0].st);

    //src_gen = vec4( 0.0f, 1.0f, 1.0f, 0.15f);
    //src_gen = src_medium;

    gl_FragColor = src_cellmemory;
}
