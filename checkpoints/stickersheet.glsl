

// ROTATION ----------------------

// 2D rotation ----------

vec2 rotate2D(vec2 p, float a){
    return p * mat2(cos(a), sin(a), -sin(a), cos(a));
}

// 3D rotation -----------

vec3 rotate3D(vec3 p, vec3 a){
    return p * mat3(
        cos(a.z) * cos(a.y), cos(a.z) * sin(a.y) * sin(a.x) - sin(a.z) * cos(a.x), cos(a.z) * sin(a.y) * cos(a.x) + sin(a.z) * sin(a.x),
        sin(a.z) * cos(a.y), sin(a.z) * sin(a.y) * sin(a.x) + cos(a.z) * cos(a.x), sin(a.z) * sin(a.y) * cos(a.x) - cos(a.z) * sin(a.x),
        -sin(a.y), cos(a.y) * sin(a.x), cos(a.y) * cos(a.x)
    );
}