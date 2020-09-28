//#version 300 es
#version 430

precision highp float;

attribute vec4 position;
uniform mat4 projmatrix;
uniform int mcols=256;
uniform int mrows=256;
out vec4 colorf;

out VertexAttrib {
  vec4 position;
} vertex;

void main() {
 int vid = gl_VertexID;
 float fvid = float(vid);
 float mmcols = float(mcols);
 float frows = float(mrows);
 float fcols = float(mmcols);
 float vj = floor(fvid / fcols);
 float vi = fvid - vj*fcols;
 float f_j = vj / frows;
 float f_i = vi / fcols;
 float red_z = abs( position.z/(0.5*(fcols+frows)) );
 colorf = vec4( 0.5+red_z, 0.5+0.5*f_i, 0.5+0.5*f_j, 1.0);
 vertex.position = projmatrix*position;
 //gl_Position = projmatrix*position;
}
