#version 330
#define M_PI 3.1415926535897932384626433832795
uniform sampler2D t_position;
            //"uniform sampler2D t_scale;
layout(points) in;
layout(triangle_strip, max_vertices = 4) out;
//layout(line_strip, max_vertices = 4) out;
            //"layout(triangles, max_vertices = 24) out;
            //"layout(points, max_vertices = 2) out;
            //"layout(line_strip, max_vertices = 4) out;
            //"uniform mat4 projmatrix;
in mat4 pmatrix[];
in float fcols[];
in float frows[];
in vec3 veye[];

in VertexAttrib {
            //" vec2 texcoord;
 vec4 color;
 vec4 position;
 vec4 scale;
 float ffvid;
 float material;
            //" int vid;
 vec4 orientation;
            //" vec4 normal;
 int i;
 int j;
} vertex[];

out vec4 vertex_color;
out vec2 vertex_coord;
out vec2 vertex_coord_2;
out float vertex_id;
out float vertex_material;
out vec3 vertex_normal;
out vec3 v_eye;

uniform int texture_mode;
uniform float texture_off_x;
uniform float texture_off_y;
uniform float texture_scale_x;
uniform float texture_scale_y;
uniform float texture_rotation;
            //"out vec4 vertex_normal;

uniform int texture_2_mode;
uniform float texture_2_off_x;
uniform float texture_2_off_y;
uniform float texture_2_scale_x;
uniform float texture_2_scale_y;
uniform float texture_2_rotation;


mat4 build_transform(vec3 pos, vec3 ang) {
 float cosX = cos(ang.x);float sinX = sin(ang.x);
 float cosY = cos(ang.y);float sinY = sin(ang.y);
 float cosZ = cos(ang.z);
 float sinZ = sin(ang.z);
 mat4 m;
 float m00 = cosY * cosZ + sinX * sinY * sinZ;
 float m01 = cosY * sinZ - sinX * sinY * cosZ;
 float m02 = cosX * sinY;
 float m03 = 0.0;
 float m04 = -cosX * sinZ;
 float m05 = cosX * cosZ;
 float m06 = sinX;
 float m07 = 0.0;
 float m08 = sinX * cosY * sinZ - sinY * cosZ;
 float m09 = -sinY * sinZ - sinX * cosY * cosZ;
 float m10 = cosX * cosY;
 float m11 = 0.0;
 float m12 = pos.x;
 float m13 = pos.y;
 float m14 = pos.z;
 float m15 = 1.0;

 ///------ Orientation ---------------------------------
 m[0][0] = m00; // first entry of the first column.
 m[0][1] = m01; // second entry of the first column.
 m[0][2] = m02;
 m[0][3] = m03;

 m[1][0] = m04; // first entry of the second column.
 m[1][1] = m05; // second entry of the second column.
 m[1][2] = m06;
 m[1][3] = m07;

 m[2][0] = m08; // first entry of the third column.
 m[2][1] = m09; // second entry of the third column.
 m[2][2] = m10;
 m[2][3] = m11;

            ///------ Position ------------------------------------
 m[3][0] = m12; // first entry of the fourth column.
 m[3][1] = m13; // second entry of the fourth column.
 m[3][2] = m14;
 m[3][3] = m15;

 return m;
}

mat2 build_rotation( float angle ) {

  mat2 m;
  float cosA = cos(angle);
  float sinA = sin(angle);
  m[0][0] = cosA;
  m[0][1] = -sinA;
  m[1][0] = sinA;
  m[1][1] = cosA;
  return m;
}

void main() {

 float ffid = mod( vertex[0].ffvid, 30.0 );
 float fmaterial = vertex[0].material;
 float sx = vertex[0].scale.x*0.5;
 float sy = vertex[0].scale.y*0.5;

 float ti = float(vertex[0].i);
 float tj = float(vertex[0].j);

 mat4 mOri = build_transform( vec3(0.0,0.0,0.0), vertex[0].orientation.xyz*(M_PI/180.0) );
 vec4 position0 = vertex[0].position;
 vec4 position1 = vertex[0].position;
 vec4 position2 = vertex[0].position;
 vec4 position3 = vertex[0].position;

 float fti = (ti) / fcols[0];
 float ftj = (tj) / frows[0];
 float fti2 = fti;
 float ftj2 = ftj;

 float t_fti = (ti) / fcols[0];
 float t_ftj = (tj) / frows[0];
 float t_dfti = (1.0) / fcols[0];
 float t_dftj = (1.0) / frows[0];
 float t_dfti2 = t_dfti;
 float t_dftj2 = t_dftj;
 float t_fti2 = t_fti;
 float t_ftj2 = t_ftj;


 if (texture_mode==0) {
   t_fti = 0.0;
   t_ftj = 0.0;
   t_dfti = 1.0;
   t_dftj = 1.0;
 }

 mat2 rotation = build_rotation( texture_rotation );
 vec2 vertex_coord0 = rotation*vec2( texture_scale_x*(t_fti), texture_scale_y*(t_ftj))+vec2(texture_off_x,texture_off_y);
 vec2 vertex_coord1 = vertex_coord0;
 vec2 vertex_coord2 = vertex_coord0;
 vec2 vertex_coord3 = vertex_coord0;

 if (texture_2_mode==0) {
   t_fti2 = 0.0;
   t_ftj2 = 0.0;
   t_dfti2 = 1.0;
   t_dftj2 = 1.0;
 }
 mat2 rotation_2 = build_rotation( texture_2_rotation );
 vec2 vertex_coord_2_0 = rotation_2*vec2( texture_2_scale_x*(t_fti2), texture_2_scale_y*(t_ftj2)) + vec2(texture_2_off_x,texture_2_off_y);
 vec2 vertex_coord_2_1 = vertex_coord_2_0;
 vec2 vertex_coord_2_2 = vertex_coord_2_0;
 vec2 vertex_coord_2_3 = vertex_coord_2_0;

 position0 = vec4(position0.xyz,1.0) + mOri*vec4( -sx, sy, 0.0, 0.0 );

 fti = (ti) / fcols[0];
 ftj = (tj+1.0) / frows[0];
 vertex_coord1 = rotation*vec2( texture_scale_x*(t_fti), texture_scale_y*(t_ftj+t_dftj))+vec2(texture_off_x,texture_off_y);
 vertex_coord_2_1 = rotation_2*vec2( texture_2_scale_x*(t_fti2), texture_2_scale_y*(t_ftj2+t_dftj2))+vec2(texture_2_off_x,texture_2_off_y);
 position1 = vec4(position1.xyz,1.0) + mOri*vec4( -sx, -sy, 0.0, 0.0 );

 fti = (ti+1.0) / fcols[0];
 ftj = (tj) / frows[0];
 vertex_coord2 = rotation*vec2( texture_scale_x*(t_fti+t_dfti), texture_scale_y*(t_ftj))+vec2(texture_off_x,texture_off_y);
 vertex_coord_2_2 = rotation_2*vec2( texture_2_scale_x*(t_fti2+t_dfti2), texture_2_scale_y*(t_ftj2))+vec2(texture_2_off_x,texture_2_off_y);
 position2 = vec4(position2.xyz,1.0) + mOri*vec4( sx, sy, 0.0, 0.0 );

 fti = (ti+1.0) / fcols[0];
 ftj = (tj+1.0) / frows[0];
 vertex_coord3 = rotation*vec2( texture_scale_x*(t_fti+t_dftj), texture_scale_y*(t_ftj+t_dftj))+vec2(texture_off_x,texture_off_y);
 vertex_coord_2_3 = rotation_2*vec2( texture_2_scale_x*(t_fti2+t_dftj2), texture_2_scale_y*(t_ftj2+t_dftj2))+vec2(texture_2_off_x,texture_2_off_y);
 position3 = vec4(position3.xyz,1.0) + mOri*vec4( sx, -sy, 0.0, 0.0 );

 // 0 - vb -> 2
 // |         x
 // va        vd
 // x         |
 // 1 <- vc - 3
 vec4 va = position1 - position0;
 vec4 vb = position2 - position0;
 vec4 vc = position1 - position3;
 vec4 vd = position2 - position3;

 vec3 v0normal = normalize( cross( va.xyz, vb.xyz ) );
 vec3 v1normal = normalize( cross( -vc.xyz, -va.xyz ) );
 vec3 v2normal = normalize( cross( -vb.xyz, -vd.xyz ) );
 vec3 v3normal = normalize( cross( vd.xyz, vc.xyz ) );

  if (vertex[0].position.w>0.0) {
    gl_Position = pmatrix[0] * (position0);
    vertex_color = vertex[0].color;
    //if (position0.z==0.0) vertex_color.a = 0.0;
    //vertex_coord = vec2( 0.0, 0.0);
    vertex_coord = vertex_coord0;
    vertex_coord_2 = vertex_coord_2_0;
    vertex_id = ffid;
    vertex_material = fmaterial;
    vertex_normal = v0normal;
    v_eye = veye[0];
    //vertex_normal = vertex[0].normal;
    EmitVertex();

    gl_Position = pmatrix[0] * (position1);
    //vertex_coord = vec2( 0.0, 1.0);
    vertex_coord = vertex_coord1;
    vertex_coord_2 = vertex_coord_2_1;
    vertex_color = vertex[0].color;
    //if (position1.z==0.0) vertex_color.a = 0.0;
    vertex_id = ffid;
    vertex_material = fmaterial;
    vertex_normal = v1normal;
    v_eye = veye[0];
              //" vertex_normal = vertex[0].normal;
    EmitVertex();

    gl_Position = pmatrix[0] * (position2);
    //vertex_coord = vec2( 1.0, 0.0);
    vertex_coord = vertex_coord2;
    vertex_coord_2 = vertex_coord_2_2;
    vertex_color = vertex[0].color;
    //if (position2.z==0.0) vertex_color.a = 0.0;
    vertex_id = ffid;
    vertex_material = fmaterial;
    vertex_normal = v2normal;
    v_eye = veye[0];
            //" vertex_normal = vertex[0].normal;
    EmitVertex();

    gl_Position = pmatrix[0] * (position3);
    //vertex_coord = vec2( 1.0, 1.0);
    vertex_coord = vertex_coord3;
    vertex_coord_2 = vertex_coord_2_3;
    vertex_color = vertex[0].color;
    //if (position3.z==0.0) vertex_color.a = 0.0;
    vertex_id = ffid;
    vertex_material = fmaterial;
    vertex_normal = v3normal;
    v_eye = veye[0];
    EmitVertex();
    EndPrimitive();
  }


}
