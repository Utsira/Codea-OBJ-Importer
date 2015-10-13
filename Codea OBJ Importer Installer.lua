--# Main
--Simple Blender .obj loader

--assumes each object has only one texture image
--currently only supports one object per file

local touches, tArray, lastPinchDist = {}, {}

function setup() 
    textMode(CORNER)
    fill(40)
    assets()

    parameter.integer("Choose",1,#Models,1)
    parameter.action("Load", function()
        local t = os.time()
        model = Mesh{mesh = OBJ.load(Models[Choose]) }
        setView()
        print (os.time()-t, "seconds")
    end)
    parameter.action("Reset camera", setView)
    parameter.action("Wireframe Mode", function()
        if model.mesh then wireframe.set(model.mesh) else alert("Load a model first") end
    end)
    parameter.watch("FPS")
    FPS=0
    setView()
    --print model list
    for i,v in ipairs(Models) do
        print(i,v.name)
    end

end

function setView()
    cam = vec3(0,0,-65) 
    rot = matrix() 
end

function draw()
    background(116, 173, 182, 255)
    text("Drag with 1 finger to rotate model on x and y\nDrag 2 fingers to pan\nPinch to track in and out\nTwist with 2 fingers to rotate around z")
    FPS=FPS*0.9+0.1/DeltaTime

    perspective() 
    camera(cam.x, cam.y,cam.z, cam.x, cam.y,0)
    modelMatrix(rot)
    if model then model:draw() end
end

function clamp(v,low,high)
    return math.min(math.max(v, low), high)
end

function processTouches(t)
    local dx,dy = 0,0
    local tArray = {}
    local inv = rot:inverse() --get the inverse of the model matrix (or transpose?), in order to convert global touches into local rotations, so that eg a swipe left always rotates the model left, regardless of the model's local orientation
    local x = inv * vec3(1,0,0) --our 3 global axes converted to local space
    local y = inv * vec3(0,1,0)
    local z = inv * vec3(0,0,1)
    --tally up the touches
    for _,t in pairs(touches) do
        dx = dx + t.deltaX
        dy = dy + t.deltaY
        tArray[#tArray+1] = {id = t.id, pos = vec2(t.x, t.y)}
    end
    if #tArray == 1 then
        --rotate around x and y axis
        rot = rot:rotate(dy, x:unpack())
        rot = rot:rotate(dx, y:unpack())
    elseif #tArray == 2 and t.id == tArray[2].id then --only process two-fingered gesture once
        --pinch to zoom
        local diff = tArray[2].pos - tArray[1].pos
        local pinchDist = diff:len() 
        local pinchDiff = pinchDist - (lastPinchDist or pinchDist)
        lastPinchDist = pinchDist
        --nb zoom and pan amount is proportional to camera distance
        cam.z = clamp(cam.z + pinchDiff * cam.z * -0.01, -2000, -5)    
        --2 finger drag to pan
        cam.x = cam.x + dx * cam.z * -0.0005
        cam.y = cam.y - dy * cam.z * -0.0005      
        --twist to rotate
        local pinchAngle = -math.deg(math.atan(diff.y, diff.x))
        local angleDiff = pinchAngle - (lastPinchAngle or pinchAngle)
        lastPinchAngle = pinchAngle
        rot = rot:rotate(angleDiff, z:unpack())
    end
end

function touched(t)
    if t.state == ENDED or t.state == CANCELLED then
        touches[t.id] = nil
        lastPinchDist = nil
        lastPinchAngle = nil
    else
        touches[t.id] = t
        processTouches(t)
    end
end

--# Assets
function assets()
    shaders()
    Models = {
    
    {name = "Tank", shade = SpecularShader, shininess = 12, specularPower = 12 }, --normals = CalculateNormals,
    {name = "low poly girl", shade = SpecularShader},
    {name = "Island lp"  },
    {name = "robot", shade = SpecularShader, shininess = 12, specularPower = 32}
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

--# Mesh
Mesh = class() 

function Mesh:init(t) 
    self.pos = t.pos or vec3(0,0,0)
    self.mesh = t.mesh
    self.size = t.size or 1
    self.angle = t.angle or vec3(0,0,0)
    self:light{light = vec4(100,-15,70,1)} --directional light direction (x,y,z,0), or point light position (x,y,z,1)
end

function Mesh:draw()
    pushMatrix()
    translate(self.pos:unpack())
    scale(self.size)
    rotate(self.angle.z)  
    rotate(self.angle.x, 1,0,0)
    rotate(self.angle.y, 0,1,0)   
    
    self:shade()
    self.mesh:draw()

    popMatrix()
end

function Mesh:shade()
    self.mesh.shader.modelMatrix=modelMatrix()    
    self.mesh.shader.light = vec4(cam.z * -2, cam.z * -3.5 ,cam.z,1)
    self.mesh.shader.eye=cam 
end

function Mesh:light(t)
    local m=self.mesh
    m.shader.light=t.light 
    m.shader.ambient=t.ambient or 0.3
    m.shader.lightColor=t.lightColor or color(255, 245, 235, 255)
end

--# OBJ
--OBJ library

OBJ={}

OBJ.assetPath="Dropbox:" --path for assets
OBJ.ioPath = os.getenv("HOME").."/Documents/Dropbox.assetpack/" --same path for files not recognised as assets. Although .obj and .mtl are text files, because they do not have the .txt suffix they are not accessible with readText or the asset picker. Therefore we use io.read, which requires a full path. 

function OBJ.load(data) --name = filename (without extension), normals = function to calculate normals, defaults to average normals, shade = shader, defaults to DiffuseShader
    local name = data.name
    local mtl = OBJ.parseMtl(name)  --the mtl material file
    local normals = data.normals or CalculateAverageNormals --the function that will be used to calculate the normals
    local obj = OBJ.parse(name, mtl, normals) --the object file
    
    --create mesh
    local m=mesh()   
    --set vertices, texCoords, normals, and colours
    m.vertices=obj.v    
    if #obj.t>0 then m.texCoords=obj.t end
    if #obj.n>0 then m.normals=obj.n end
    if #obj.c>0 then m.colors=obj.c 
    else m:setColors(color(255))
    end 
    
    --texture and shader
    local shade = data.shade or DiffuseShader
    if mtl.texture then
        local tex=OBJ.assetPath..mtl.texture
        m.texture=tex
        shade =  DiffuseTexShader
    end    
    m.shader=shade
    m.shader.shininess = data.shininess or 1.2 --settings for specular shader
    m.shader.specularPower = data.specularPower or 32
    return m
end

function OBJ.getFile(name, ext) --this could just be replaced with readText, if readText could see .obj and .mtl
    --attempt to open .obj file
    local path = OBJ.ioPath..name..ext
    local file, err = io.open(path, "r")
    local data
    if file then
        data=file:read("*all")
        print(name..ext, ": ", data:len(), " bytes")
        file:close()
    else 
        print(name, err)
    end
    return data
end

function OBJ.parse(name,material, normals)
    local data = OBJ.getFile(name, ".obj")
    
    local p, v, tx, t, np, n, c={},{},{},{},{},{},{} 
    
    local mtl=material.mtl
    local mname
    
    for code, v1,v2,v3 in data:gmatch("(%a+) ([%w%p]+) *([%d%p]*) *([%d%p]*)[\r\n]") do --one code and between one and three number values (that might be negative and have decimal points, hence %p punctuation)
        -- print(code, v1, v2, v3)
        if code == "usemtl" then mname = v1
        elseif code=="v" then --point position
            p[#p+1]=vec3(v1,v2,v3) 
        elseif code=="vn" then --point normal
            np[#np+1]=vec3(v1,v2,v3) 
        elseif code=="vt" then --texture co-ord
            tx[#tx+1]=vec2(v1,v2) 
        elseif code=="f" then --vertex
            local pts,ptex,pnorm=OBJ.GetList(v1,v2,v3)
            if #pts==3 then
                for i=1,3 do
                    v[#v+1]=p[tonumber(pts[i])]
                    if mname then c[#c+1]=mtl[mname].Kd end --set vertex color according to diffuse component of current material
                end
                if ptex then for i=1,3 do t[#t+1]=tx[tonumber(ptex[i])] end end
                if pnorm then for i=1,3 do n[#n+1]=np[tonumber(pnorm[i])] end end
            else
                alert("add a triangulate modifier to the mesh and re-export", "non-triangular face detected") --insist on triangular faces
                return
            end
        end
    end
    if #n<#v then n=normals(v) end
    print (name..": "..#v.." vertices processed")
    return {v=v, t=t, c=c, n=n}
end

function OBJ.parseMtl(name)
    local data = OBJ.getFile(name, ".mtl")
    local mtl={}
    local mname, map, path
    
    for code, v1,v2,v3 in data:gmatch("([%a_]+) ([%w%p]+) *([%d%p]*) *([%d%p]*)[\r\n]") do --one code and between one and three number values (that might be negative and have decimal points, hence %p punctuation)
        --   print(code, v1, v2, v3)
        if code=="newmtl" then
            mname=v1
            mtl[mname]={}
        elseif code=="Ka" then --ambient
            mtl[mname].Ka=color(v1,v2,v3) * 255 
        elseif code=="Kd" then --diffuse
            mtl[mname].Kd=color(v1,v2,v3) * 255 --this is the important one
        elseif code=="Ks" then --specular
            mtl[mname].Ks=color(v1,v2,v3) * 255 
        elseif code=="Ns" then --specular exponent
            mtl[mname].Ns=v1 
        elseif code=="illum" then --illumination code
            mtl[mname].illum=v1 
        elseif code=="map_Kd" then --texture map name. New: only 1 texture per model
            map = v1:match("([%w_]+)%.") --remove extension
        end
    end
    
    if map then
        local y=readImage(OBJ.assetPath..map)
        if not y then
            alert(map.."Use path “copy” in Blender .obj export", "Image not found")
            return
        end
    end
    return {mtl=mtl, texture=map} 
end

function OBJ.GetList(...)
    local p,t,n={},{},{}
    
    local inkey={...}
    
    for i=1,#inkey do
        for v1,v2,v3 in inkey[i]:gmatch("(%d+)/?(%d*)/?(%d*)") do
            if v2~="" and v3~="" then
                p[i]=math.abs(v1)
                t[i]=math.abs(v2)
                n[i]=math.abs(v3)
            elseif v2~="" then
                p[i]=math.abs(v1)
                t[i]=math.abs(v2)
            else
                p[i]=math.abs(v1)
                
            end
        end
    end
    return p,t,n
end

function CalculateNormals(vertices)
    --this assumes flat surfaces, and hard edges between triangles
    local norm = {}
    for i=1, #vertices,3 do --calculate normal for each set of 3 vertices
        local n = ((vertices[i+1] - vertices[i]):cross(vertices[i+2] - vertices[i])):normalize()
        norm[i] = n --then apply it to all 3
        norm[i+1] = n
        norm[i+2] = n
    end
    return norm
end   

function CalculateAverageNormals(vertices)
    --average normals at each vertex
    --first get a list of unique vertices, concatenate the x,y,z values as a key
    local norm,unique= {},{}
    for i=1, #vertices do
        unique[vertices[i].x ..vertices[i].y..vertices[i].z]=vec3(0,0,0)
    end
    --calculate normals, add them up for each vertex and keep count
    for i=1, #vertices,3 do --calculate normal for each set of 3 vertices
        local n = (vertices[i+1] - vertices[i]):cross(vertices[i+2] - vertices[i]) 
        for j=0,2 do
            local v=vertices[i+j].x ..vertices[i+j].y..vertices[i+j].z
            unique[v]=unique[v]+n  
        end
    end
    --calculate average for each unique vertex
    for i=1,#unique do
        unique[i] = unique[i]:normalize()
    end
    --now apply averages to list of vertices
    for i=1, #vertices,3 do --calculate average
        local n = (vertices[i+1] - vertices[i]):cross(vertices[i+2] - vertices[i]) 
        for j=0,2 do
            norm[i+j] = unique[vertices[i+j].x ..vertices[i+j].y..vertices[i+j].z]
        end
    end
    return norm 
end 

--# Wireframe
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
    highp vec3 tdist = smoothstep(vec3(0.0), d * 2., vNormal); //thicken line by multiplying d

    //2 methods: 1. discard method: best way of ensuring back facing struts show through
    if (min(min(tdist.x, tdist.y), tdist.z) > 0.5) discard; 
    else gl_FragColor = col;
    
    //2. alpha method means some rear faces wont show. Would be good for a "solid" mode though
    //gl_FragColor = mix(col, vec4(0.), min(min(tdist.x, tdist.y), tdist.z)); 
}]]