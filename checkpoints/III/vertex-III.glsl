uniform float time;
uniform vec2 resolution;
uniform vec2 mouse;
uniform vec3 spectrum;
uniform mat4 mvp;
uniform float scale;
uniform float rotationSpeed;

attribute vec4 a_position;
attribute vec3 a_normal;
attribute vec2 a_texcoord;

varying vec3 v_normal;
varying vec2 v_texcoord;

#define PI 3.1415926536

vec2 rotate2D(vec2 p, float a){
    return p * mat2(cos(a), sin(a), -sin(a), cos(a));
}

vec3 rotate3D(vec3 p, vec3 a){
    return p * mat3(
        cos(a.z) * cos(a.y), cos(a.z) * sin(a.y) * sin(a.x) - sin(a.z) * cos(a.x), cos(a.z) * sin(a.y) * cos(a.x) + sin(a.z) * sin(a.x),
        sin(a.z) * cos(a.y), sin(a.z) * sin(a.y) * sin(a.x) + cos(a.z) * cos(a.x), sin(a.z) * sin(a.y) * cos(a.x) - cos(a.z) * sin(a.x),
        -sin(a.y), cos(a.y) * sin(a.x), cos(a.y) * cos(a.x)
    );
}

void main(void)
{
    v_normal    = a_normal;
    v_texcoord  = a_texcoord;
    
    vec4 pos = a_position;
    
    float dsp = sin(5.0*v_texcoord.y + time*2.0);
    
    
    float t = length(spectrum)/0.8;         // set a length of 3 spectrum as t = translation (you need to play some audio)
    
    pos.x += pos.x < 0.0 ? -t : t;          // translate the x position, if x position is smaller than zero ? subtract t : otherwise add t
    
    float rr = rotationSpeed;
    if(spectrum.y > 0.81){
    rr *= 1.5;
    }
    pos.xyz = rotate3D(                     // rotate vertex in 3D
                pos.xyz,                    // original position
                    vec3(
                        cos(time*rotationSpeed/0.5) / PI, // rotate x axis
                        time*rr,               // rotate y axis
                        0.0                 // rotate z axis
                    )
                );
    
    float s = fract(time / 2.0) / 0.5 - 1.0;
    
    /*
            s is a fraction of time divided by two (looping from zero to one)
            multiply the fraction by two and subtract one
            now s goes from -1 to 1 looping
    */
    
    
    pos.x += pos.y < s ? t : -t;            // translate the x position, if y position is smaller than s ? add t : otherwise subtract t
    
    pos.xyz += a_normal.xyz * spectrum.xyz; // translate all the axes by the normal, normal is the direction of the surface, multiplied by spectrum x y z
    
    // twist
//    pos.xz = rotate2D(pos.xz, pos.y / 0.5 * sin(time)); // we can twist along vertical axis by rotating based on y position, animated using sine wave of time
    pos.xyz *= scale+(dsp*0.04*spectrum);
    
    gl_Position = mvp * pos;
}