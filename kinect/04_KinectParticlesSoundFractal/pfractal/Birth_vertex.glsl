#extension GL_EXT_gpu_shader4 : enable


uniform vec2 tempo_angle;

void main()
{
	gl_TexCoord[0] = gl_MultiTexCoord0;
	//gl_Vertex.z = gl_Vertex.z*(1.0+cos(tempo_angle));
	gl_Position = ftransform();
} 
