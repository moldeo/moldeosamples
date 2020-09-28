#version 330
#define M_PI 3.1415926535897932384626433832795
uniform sampler2D t_position;
            //"uniform sampler2D t_scale;
layout(points) in;
//layout(triangle_strip, max_vertices = 4) out;
layout(line_strip, max_vertices = 4) out;
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
 int ip;
 int jp;
 float age;
} vertex[];

out vec4 vertex_color;
out vec2 vertex_coord;
out float vertex_id;
out float vertex_material;
out vec3 vertex_normal;
out vec3 v_eye;


uniform float texture_off_x;
uniform float texture_off_y;
uniform float texture_scale_x;
uniform float texture_scale_y;
uniform float texture_rotation;
            //"out vec4 vertex_normal;

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
 float tip = float(vertex[0].ip);
 float tjp = float(vertex[0].jp);

 float fti = (ti) / fcols[0];
 float ftj = (tj) / frows[0];
 float ftip = (tip) / fcols[0];
 float ftjp = (tjp) / frows[0];

 mat4 mOri = build_transform( vec3(0.0,0.0,0.0), vertex[0].orientation.xyz*(M_PI/180.0) );
 vec4 position0 = vertex[0].position;
 position0 = vec4( texture2D( t_position, vec2( fti, ftj ) ).xyz, 1.0 );
 vec4 position1 = vertex[0].position;
 position1 = vec4( texture2D( t_position, vec2( ftip, ftjp ) ).xyz, 1.0 );

 vec4 position2 = vertex[0].position;
 vec4 position3 = vertex[0].position;

 mat2 rotation = build_rotation( texture_rotation );
 vec2 vertex_coord0 = rotation*vec2( texture_scale_x*(fti), texture_scale_y*(ftj))+vec2(texture_off_x,texture_off_y);
 vec2 vertex_coord1 = vertex_coord0;

if (vertex[0].position.w>0) {
 gl_Position = pmatrix[0] * vec4(position0.xyz,1.0);
 vertex_color = vertex[0].age*vertex[0].color;
 //if (position0.z==0.0) vertex_color.a = 0.0;
 //vertex_coord = vec2( 0.0, 0.0);
 vertex_coord = vertex_coord0;
 vertex_id = ffid;
 vertex_material = fmaterial;
 vertex_normal = vec3(0.0,0.0,1.0);
 v_eye = veye[0];
 //vertex_normal = vertex[0].normal;
 EmitVertex();

 gl_Position = pmatrix[0] * (vec4(position1.xyz,1.0));
 vertex_color = vertex[0].color;
 //if (position0.z==0.0) vertex_color.a = 0.0;
 //vertex_coord = vec2( 0.0, 0.0);
 vertex_coord = vertex_coord0;
 vertex_id = ffid;
 vertex_material = fmaterial;
 vertex_normal = vec3(0.0,0.0,1.0);
 v_eye = veye[0];
 //vertex_normal = vertex[0].normal;
 EmitVertex();
}

/*
 vec2 vertex_coord2 = vertex_coord0;
 vec2 vertex_coord3 = vertex_coord0;

 if (0<=ti && ti<(fcols[0]-1) && 0<=tj && tj<(frows[0]-1)) {
   position0 = vec4( texture2D( t_position, vec2( fti, ftj ) ).xyz, 1.0 );

   fti = (ti) / fcols[0];
   ftj = (tj+1.0) / frows[0];
   vertex_coord1 = rotation*vec2( texture_scale_x*(fti), texture_scale_y*(ftj))+vec2(texture_off_x,texture_off_y);
   position1 = vec4( texture2D( t_position, vec2( fti, ftj ) ).xyz, 1.0 )+vec4( 0.0, -1.0*sy, 0.0, 0.0);

   fti = (ti+1.0) / fcols[0];
   ftj = (tj) / frows[0];
   vertex_coord2 = rotation*vec2( texture_scale_x*(fti), texture_scale_y*(ftj))+vec2(texture_off_x,texture_off_y);
   position2 = vec4( texture2D( t_position, vec2( fti, ftj ) ).xyz, 1.0 )+vec4( -1.0*sx, 0.0, 0.0, 0.0);

   fti = (ti+1.0) / fcols[0];
   ftj = (tj+1.0) / frows[0];
   vertex_coord3 = rotation*vec2( texture_scale_x*(fti), texture_scale_y*(ftj))+vec2(texture_off_x,texture_off_y);
   position3 = vec4( texture2D( t_position, vec2( fti, ftj )).xyz, 1.0 )+vec4( -1.0*sx, -1.0*sy, 0.0, 0.0);
 }

 vec4 position_mean = position0 + position1 + position2 + position3;
 position_mean = position_mean * 0.25;
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
 //vec3 v2normal = normalize( cross( v2.xyz, v3.xyz ) );

 float diff0 = length(position0 - position_mean);
 float diff1 = length(position1 - position_mean);
 float diff2 = length(position2 - position_mean);
 float diff3 = length(position3 - position_mean);

 if (position0.z!=0.0 && diff0<0.5) {
              //" gl_Position = pmatrix[0] * (vertex[0].position + mOri*vec4( -sx, sy, 0.0, 0.0 ));
   gl_Position = pmatrix[0] * (position0);
   vertex_color = vertex[0].color;
   //if (position0.z==0.0) vertex_color.a = 0.0;
   //vertex_coord = vec2( 0.0, 0.0);
   vertex_coord = vertex_coord0;
   vertex_id = ffid;
   vertex_material = fmaterial;
   vertex_normal = v0normal;
   v_eye = veye[0];
  //vertex_normal = vertex[0].normal;
   EmitVertex();
}

 if (position1.z!=0.0 && diff1<0.5) {
              //" gl_Position = pmatrix[0] * (vertex[0].position + mOri * vec4( -sx, -sy, 0.0, 0.0 ) );
   gl_Position = pmatrix[0] * (position1);
   //vertex_coord = vec2( 0.0, 1.0);
   vertex_coord = vertex_coord1;
   vertex_color = vertex[0].color;
   //if (position1.z==0.0) vertex_color.a = 0.0;
   vertex_id = ffid;
   vertex_material = fmaterial;
   vertex_normal = v1normal;
   v_eye = veye[0];
              //" vertex_normal = vertex[0].normal;
   EmitVertex();
}
            //" gl_Position = pmatrix[0] * (vertex[0].position + mOri * vec4( sx, sy, 0.0, 0.0 ) );
 if (position2.z!=0.0  && diff2<0.5) {
   gl_Position = pmatrix[0] * (position2);
   //vertex_coord = vec2( 1.0, 0.0);
   vertex_coord = vertex_coord2;
   vertex_color = vertex[0].color;
   //if (position2.z==0.0) vertex_color.a = 0.0;
   vertex_id = ffid;
   vertex_material = fmaterial;
   vertex_normal = v2normal;
   v_eye = veye[0];
            //" vertex_normal = vertex[0].normal;
   EmitVertex();
  }
            //" gl_Position = pmatrix[0] * (vertex[0].position + mOri * vec4( sx, -sy, 0.0, 0.0 ));
 if (position3.z!=0.0  && diff3<0.5 ) {
   gl_Position = pmatrix[0] * (position3);
   //vertex_coord = vec2( 1.0, 1.0);
   vertex_coord = vertex_coord3;
   vertex_color = vertex[0].color;
   //if (position3.z==0.0) vertex_color.a = 0.0;
   vertex_id = ffid;
   vertex_material = fmaterial;
   vertex_normal = v3normal;
   v_eye = veye[0];
   EmitVertex();
 }
*/
            //" vertex_normal = vertex[0].normal;

 EndPrimitive();
}
