--Simple Blender .obj loader

--assumes each object has only one texture image
--currently only supports one object per file
--todo: remote images

local touches, tArray, lastPinchDist = {}, {}

function setup() 
    textMode(CORNER)
    strokeWidth(3)
    fill(40)
    assets()

    parameter.integer("Choose",1,#Models,1)
    parameter.boolean("save_model_to_Dropbox", false)
    parameter.action("Load", function()
        --[[
        local t = os.time()
        model = Mesh{mesh = OBJ.load(Models[Choose]) }
        setView()
        print (os.time()-t, "seconds")
          ]]
        loadModel1(Models[Choose])
    end)
    parameter.action("Reset camera", setView)
    parameter.action("Wireframe Mode", function()
        if model and model.mesh then wireframe.set(model.mesh) else alert("Load a model first") end
    end)
    parameter.number("WireframeStrokeWidth", 0.5, 15, strokeWidth(), function() 
        if model and model.mesh then 
            strokeWidth(WireframeStrokeWidth)
            model.mesh.shader.strokeWidth = WireframeStrokeWidth 
        end
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

    FPS=FPS*0.9+0.1/DeltaTime

    perspective() 
    camera(cam.x, cam.y,cam.z, cam.x, cam.y,0)
    modelMatrix(rot)
    if model then model:draw() end
    ortho()
    viewMatrix(matrix())
    resetMatrix()
    text("Drag with 1 finger to rotate model on x and y\nDrag 2 fingers to pan\nPinch to track in and out\nTwist with 2 fingers to rotate around z")
end

function clamp(v,low,high)
    return math.min(math.max(v, low), high)
end

function processTouches(t)
    local dx,dy = 0,0
    local tArray = {}
    local i = rot:inverse() --get the inverse of the model matrix (or transpose?), in order to convert global touches into local rotations, so that eg a swipe left always rotates the model left, regardless of the model's local orientation
    local x = vec3(i[1], i[2], i[3]) --our 3 global axes converted to local space
    local y = vec3(i[5], i[6], i[7]) 
    local z = vec3(i[9], i[10], i[11]) 
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
        rot = rot:translate( (((dy * y) - (dx * x)) * cam.z * -0.0005):unpack()) 
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
