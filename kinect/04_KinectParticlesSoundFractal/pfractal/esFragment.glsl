#version 430

precision highp float;
uniform sampler2D t_image;
varying vec4 colorf;

void main() {
  gl_FragColor = vec4( 1.0, colorf.g, colorf.b, 1.0 );
}
