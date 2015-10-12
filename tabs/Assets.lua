function assets()
    shaders()
    Models = {
    
    {name = "Tank", shade = SpecularShader, shininess = 12, specularPower = 12 }, --normals = CalculateNormals,
    {name = "low poly girl", shade = SpecularShader},
    {name = "Island lp"  }
    }
end

function shaders()
    DiffuseShader = shader(Diffuse.vert, Diffuse.frag)
    DiffuseTexShader = shader(DiffuseTex.vert, DiffuseTex.frag)
    DiffuseTexTileShader = shader(DiffuseTex.vert, DiffuseTexTile.frag)
    SpecularShader = shader(DiffuseSpecular.vert, DiffuseSpecular.frag)
    SpecularTexShader = shader(DiffuseSpecularTex.vert, DiffuseSpecularTex.frag)
end

DiffuseTex = { 
vert = [[

uniform mat4 modelViewProjection;
uniform mat4 modelMatrix;

attribute vec4 position;
attribute vec4 color;
attribute vec2 texCoord;
attribute vec3 normal;

varying lowp vec4 vNormal;
varying mediump vec4 vColor;
varying highp vec2 vTexCoord;
varying lowp vec4 vPosition;

void main()
{
    vNormal = normalize(modelMatrix * vec4( normal, 0.0 ));
    vPosition = modelMatrix * position;
    vColor = color;
    vTexCoord = texCoord;
    gl_Position = modelViewProjection * position;
}

]],

frag = [[

precision highp float;

uniform lowp sampler2D texture;
uniform float ambient; // --strength of ambient light 0-1
uniform vec4 light; //--directional light direction (x,y,z,0), or point light position (x,y,z,1)
uniform vec4 lightColor; //--directional light colour

varying lowp vec4 vNormal;
varying mediump vec4 vColor;
varying highp vec2 vTexCoord;
varying lowp vec4 vPosition;

void main()
{
    lowp vec4 pixel= texture2D( texture, vTexCoord ) * vColor; 
    lowp vec4 ambientLight = pixel * ambient;
    lowp vec4 norm = normalize(vNormal);
    lowp vec4 lightDirection = normalize (light - vPosition * light.w);
    lowp vec4 diffuse = pixel * lightColor * max( 0.0, dot( norm, lightDirection ));
    vec4 totalColor = ambientLight + diffuse;
    totalColor.a=vColor.a;
    gl_FragColor=totalColor;
}

]]}

DiffuseTexTile = { 

frag = [[

precision highp float;

uniform lowp sampler2D texture;
uniform float ambient; // --strength of ambient light 0-1
uniform vec4 light; //--directional light direction (x,y,z,0)
uniform vec4 lightColor; //--directional light colour

varying lowp vec4 vNormal;
varying mediump vec4 vColor;
varying highp vec2 vTexCoord;
varying lowp vec4 vPosition;

void main()
{
    lowp vec4 pixel= texture2D( texture, fract(vTexCoord) ) * vColor; 
    lowp vec4 ambientLight = pixel * ambient;
    lowp vec4 norm = normalize(vNormal);
    lowp vec4 lightDirection = normalize (light - vPosition * light.w);
    lowp vec4 diffuse = pixel * lightColor * max( 0.0, dot( norm, lightDirection ));
    vec4 totalColor = ambientLight + diffuse;
    totalColor.a=vColor.a;
    gl_FragColor=totalColor;
}

]]}

Diffuse={ --no texture
vert = [[

uniform mat4 modelViewProjection;
uniform mat4 modelMatrix;

attribute vec4 position;
attribute vec4 color;
attribute vec3 normal;

varying lowp vec4 vNormal;
varying mediump vec4 vColor;
varying lowp vec4 vPosition;

void main()
{
    vNormal = normalize(modelMatrix * vec4( normal, 0.0 ));
    vColor = color;
    vPosition = modelMatrix * position;
    gl_Position = modelViewProjection * position;
}

]],

frag = [[

precision highp float;

uniform float ambient; // --strength of ambient light 0-1
uniform vec4 light; //--directional light direction (x,y,z,0)
uniform vec4 lightColor; //--directional light colour

varying lowp vec4 vNormal;
varying mediump vec4 vColor;
varying lowp vec4 vPosition;

void main()
{

    lowp vec4 ambientLight = vColor * ambient;
    lowp vec4 norm = normalize(vNormal);
    lowp vec4 lightDirection = normalize(light - vPosition * light.w);
    lowp vec4 diffuse = vColor * lightColor * max( 0.0, dot( norm, lightDirection ));
    vec4 totalColor = ambientLight + diffuse;
    totalColor.a=vColor.a;
    gl_FragColor=totalColor;
}

]]
}

DiffuseSpecular={
vert = [[

uniform mat4 modelViewProjection;
uniform mat4 modelMatrix;

attribute vec4 position;
attribute vec4 color;
attribute vec3 normal;

varying lowp vec4 vNormal;
varying lowp vec4 vPosition;
varying lowp vec4 vColor;

void main()
{
    vNormal = normalize(modelMatrix * vec4( normal, 0.0 ));
    vPosition = modelMatrix * position;
    vColor = color;
    gl_Position = modelViewProjection * position;
}

]],

frag = [[

precision highp float;

uniform float ambient; // --strength of ambient light 0-1
uniform vec4 light; //--directional light direction (x,y,z,0)
uniform vec4 lightColor; //--directional light colour
uniform vec4 eye; // -- position of camera (x,y,z,1)
uniform float specularPower; //higher number = smaller, harder highlight
uniform float shininess;

varying lowp vec4 vNormal;
varying lowp vec4 vPosition;
varying lowp vec4 vColor;

void main()
{

    lowp vec4 ambientLight = vColor * ambient;
    lowp vec4 norm = normalize(vNormal);
    lowp vec4 lightDirection = normalize(light - vPosition * light.w);
    lowp vec4 diffuse = vColor * lightColor * max( 0.0, dot( norm, lightDirection ));

    //specular blinn-phong
    vec4 cameraDirection = normalize( eye - vPosition );
    vec4 halfAngle = normalize( cameraDirection + lightDirection );
    float spec = pow( max( 0.0, dot( norm, halfAngle)), specularPower );
    lowp vec4 specular = lightColor  * spec * shininess; 

    vec4 totalColor = ambientLight + diffuse + specular;
    totalColor.a=vColor.a;
    gl_FragColor=totalColor;
}

]]
}

DiffuseSpecularTex={
vert = [[

uniform mat4 modelViewProjection;
uniform mat4 modelMatrix;

attribute vec4 position;
attribute vec4 color;
attribute vec3 normal;
attribute vec2 texCoord;

varying highp vec2 vTexCoord;
varying lowp vec4 vNormal;
varying lowp vec4 vPosition;
varying lowp vec4 vColor;

void main()
{
    vNormal = normalize(modelMatrix * vec4( normal, 0.0 ));
    vPosition = modelMatrix * position;
    vColor = color;
    vTexCoord = texCoord;
    gl_Position = modelViewProjection * position;
}

]],

frag = [[

precision highp float;

uniform lowp sampler2D texture;
uniform float ambient; // --strength of ambient light 0-1
uniform vec4 light; //--directional light direction (x,y,z,0)
uniform vec4 lightColor; //--directional light colour
uniform vec4 eye; // -- position of camera (x,y,z,1)
uniform float specularPower; //higher number = smaller highlight
uniform float shininess;

varying lowp vec4 vNormal;
varying lowp vec4 vPosition;
varying lowp vec4 vColor;
varying highp vec2 vTexCoord;

void main()
{
    lowp vec4 pixel= texture2D( texture, vec2( fract(vTexCoord.x), fract(vTexCoord.y) ) ) * vColor; 
    lowp vec4 ambientLight = pixel * ambient;
    lowp vec4 norm = normalize(vNormal);
    lowp vec4 lightDirection = normalize(light - vPosition * light.w);
    lowp vec4 diffuse = pixel * lightColor * max( 0.0, dot( norm, lightDirection ));

    //specular blinn-phong
    vec4 cameraDirection = normalize( eye - vPosition );
    vec4 halfAngle = normalize( cameraDirection + lightDirection );
    float spec = pow( max( 0.0, dot( norm, halfAngle)), specularPower );
    lowp vec4 specular = lightColor  * spec * shininess; 

    vec4 totalColor = ambientLight + diffuse + specular;
    totalColor.a=vColor.a;
    gl_FragColor=totalColor;
}

]]
}
