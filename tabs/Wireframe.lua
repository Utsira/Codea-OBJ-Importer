wireframe = {}

function wireframe.set(m)
    local cc = {}
    for i = 1, m.size/3 do
        table.insert(cc, vec3(1,0,0))
        table.insert(cc, vec3(0,1,0))
        table.insert(cc, vec3(0,0,1))
    end
    m.normals = cc
    m.shader = shader(wireframe.vert, wireframe.frag)
end

wireframe.vert = [[
uniform mat4 modelViewProjection;

attribute vec4 position;
attribute vec4 color;
attribute vec3 normal;

varying highp vec4 vColor;
varying highp vec3 vNormal;

void main(void) {
    vColor = color;
    vNormal = normal;
    gl_Position = modelViewProjection * position;
}]]

wireframe.frag = [[
#extension GL_OES_standard_derivatives : enable

varying highp vec4 vColor;
varying highp vec3 vNormal;

void main(void) {
    highp vec4 col = vColor;
    if (!gl_FrontFacing) col.rgb *= 0.5; //darken rear-facing struts
    highp vec3 d = fwidth(vNormal);    
    highp vec3 tdist = smoothstep(vec3(0.0), d * 3., vNormal); //thicken line by multiplying d

    //2 methods: 1. discard method: best way of ensuring back facing struts show through
    if (min(min(tdist.x, tdist.y), tdist.z) > 0.5) discard; 
    else gl_FragColor = mix(col, vec4(0.), 2. * min(min(tdist.x, tdist.y), tdist.z)); // anti-aliasing
    
    //2. alpha method means some rear faces wont show. Would be good for a "solid" mode though
    //gl_FragColor = mix(col, vec4(0.), min(min(tdist.x, tdist.y), tdist.z)); 
}]]