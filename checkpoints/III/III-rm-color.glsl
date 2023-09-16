#ifdef GL_ES
precision highp float;
#endif

uniform float time;
uniform vec2 resolution;
uniform vec3 spectrum;

uniform sampler2D prevFrame;
uniform sampler2D prevPass;
uniform vec3 Pos;
uniform vec3 IR;

varying vec3 v_normal;
varying vec2 v_texcoord;

#define MAX_STEPS 100
#define MAX_DIST 100.
#define SURF_DIST .001
#define TAU 6.283185
#define PI 3.141592
#define S smoothstep
#define T time

// Rotation function
mat2 Rot(float a){
   float s = sin(a);
   float c = cos(a);
   return mat2(c, -s, s, c);   
}

// Smooth min
float smin( float a, float b, float k ) {
    float h = clamp( 0.5+0.5*(b-a)/k, 0., 1. );
    return mix( b, a, h ) - k*h*(1.0-h);
}


// noise func
float hash( float n ) { return fract(sin(n)*753.5453123); }
float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
   
    float n = p.x + p.y*157.0 + 113.0*p.z;
    return mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
                   mix( hash(n+157.0), hash(n+158.0),f.x),f.y),
               mix(mix( hash(n+113.0), hash(n+114.0),f.x),
                   mix( hash(n+270.0), hash(n+271.0),f.x),f.y),f.z);
}


// ~~~~~~~~~~ Shapes ~~~~~~~
//Sphere
float sdSphere(vec3 p, float s){ return length(p)-s;}
// Box
float sdBox(vec3 p, vec3 s){
   p = abs(p) - s;
   return length(max(p, 0.)) + min(max(p.x, max(p.y, p.z)), 0.0);
}
// Torus
float sdTorus( vec3 p, vec2 t ){return length( vec2(length(p.xz)-t.x,p.y) )-t.y;}
// Hex
float sdHexPrism(vec3 p, vec2 h)
{
    vec3 q = abs(p);

    const vec3 k = vec3(-0.8660254, 0.5, 0.57735);
    p = abs(p);
    p.xy -= 2.0*min(dot(k.xy, p.xy), 0.0)*k.xy;
    vec2 d = vec2(
       length(p.xy - vec2(clamp(p.x, -k.z*h.x, k.z*h.x), h.x))*sign(p.y - h.x),
       p.z-h.y );
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}
//Pyramid
float sdPyramid(in vec3 p, in float h)
{
    float m2 = h*h + 0.25;
    // symmetry
    p.xz = abs(p.xz);
    p.xz = (p.z>p.x) ? p.zx : p.xz;
    p.xz -= 0.5;
    // project into face plane (2D)
    vec3 q = vec3( p.z, h*p.y - 0.5*p.x, h*p.x + 0.5*p.y);
    float s = max(-q.x,0.0);
    float t = clamp( (q.y-0.5*p.z)/(m2+0.25), 0.0, 1.0 );
    float a = m2*(q.x+s)*(q.x+s) + q.y*q.y;
   float b = m2*(q.x+0.5*t)*(q.x+0.5*t) + (q.y-m2*t)*(q.y-m2*t);
    float d2 = min(q.y,-q.x*m2-q.y*0.5) > 0.0 ? 0.0 : min(a,b);
    // recover 3D and scale, and add sign
    return sqrt( (d2+q.z*q.z)/m2 ) * sign(max(q.z,-p.y));;
}

// ~~~~~~~~~~~~~~~~~~~ |Create the scene| ~~~~~~~~~~~~~~~
float GetDist(vec3 p){

   // wPos.xy = mod(wPos.xy + size*0.05, size) - size*0.5; // multiple shapes

   float dB = sdBox(p, vec3(1., 1., 1.)); // Box
   dB = sdBox(p, vec3(.7, 4.5, 1.)) + noise(p * 1. + time*0.7); // Box
   float dSA = sdSphere(p, 1.); // Sphere A
   float dPy = sdHexPrism(p, vec2(1.0, .2));
   
   float dF = max(-dSA, dB); // substract
   dF = smin(dB, dSA, 1.);
   
   return dF;
}
// ~~~~~~~~~ RayMarching stuff ~~~~~~~~~~~~~~~
vec3 GetNormal(vec3 p) {
   float d = GetDist(p);
    vec2 e = vec2(.001, 0);
    
    vec3 n = d - vec3(
        GetDist(p-e.xyy),
        GetDist(p-e.yxy),
        GetDist(p-e.yyx));
    
    return normalize(n);
}
// ~~~~~~~~~~~~~ Texture stuff ~~~~~~~~~~~~~
// color palette
vec3 palette(in vec3 t, in vec3 a, in vec3 b, in vec3 c, in vec3 d) { return a + b*cos(38.21*(c*t+d) ); }
// diffuse material
float diffuse (in vec3 light, in vec3 nor) {return clamp(0., 1., dot(nor, light));}
// Define base color
vec3 baseColor (in vec3 pos, in vec3 nor, in vec3 rayDir, in float rayDepth) {
    vec3 color = vec3(.0); 
    float dNR = dot(nor, -rayDir);  
    color = palette(vec3(dNR), vec3(IR.x), vec3(IR.y), vec3(IR.z), vec3(0.60, 0.1, 0.4)); //<------- Color
    return color;
}
// Make the shade
vec4 shade (vec3 pos, vec3 rayDir, float rayDepth) {
    vec3 nor = GetNormal(pos);
    
    nor += 0.1 * sin(8. * nor);
    nor = normalize(nor);
    
    vec3 color = palette(
        nor,
        vec3(1.1, 0.5, 1.2), // brightness
        vec3(rayDepth) * 1., // contrast
        vec3(1.), // osc
        vec3(0.1, 0.6, 0.6) // phase
    );
    
    vec3 lightPos = vec3(0.0, 0., 1.);
    
    float dif = diffuse(lightPos, nor);
    color = dif * baseColor(pos, nor, rayDir, rayDepth);
    vec4 shapeColor = vec4(color, 1.0);

    return shapeColor;
}

vec4 RayMarch(vec3 ro, vec3 rd) {
   float dO=0.5;
   float bg = sin(rd.y*.1 + 0.9); // <------------ background
   // shooting the ray
    for (int i=0; i < MAX_STEPS; i++) {
        // steps traveled
        float dS = GetDist(ro + rd * dO);
        dO += dS;
        
        //if(dO>MAX_DIST || abs(dS)<SURF_DIST) break;
        if (dS < SURF_DIST) return shade(ro + rd * dO, rd, dO); // We're inside the scene - magic happens here
        if (dO > MAX_DIST) return vec4(0.9*bg, 0.9*bg, 0.9*bg, 1.); // We've gone too far (Backgound)
    }
   return vec4(0, 0, 0, 1);
}

vec3 GetRayDir(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l-p),
        r = normalize(cross(vec3(0,1,0), f)),
        u = cross(f,r),
        c = f*z,
        i = c + uv.x*r + uv.y*u,
        d = normalize(i);
    return d;
}




void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy)/resolution.y;
    vec3 col = vec3(0.0);
    
    vec3 ro = vec3(0.0, .0, Pos.z);
    ro.yz *= Rot(-Pos.y*PI+1.0);
    ro.xz *= Rot(-Pos.x + time*0.0*TAU);
    
    vec3 rd = GetRayDir(uv, ro, vec3(0.0, 0.0, 0.0), 1.0);
    
    vec4 d = RayMarch(ro, rd);
      
      col = pow(col, vec3(0.4545));
      
    gl_FragColor = RayMarch(ro, rd);
   // gl_FragColor = vec4(col, 1.0);
}