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
        print (os.time()-t, "seconds")
    end)
    parameter.action("Reset camera", function() cam = vec3(0,0,-65) rot = vec3(0,0,0) end)
    parameter.watch("FPS")
    FPS=0
    cam = vec3(0,0,-65) 
    rot = vec3(0,0,0)
    --print model list
    for i,v in ipairs(Models) do
        print(i,v.name)
    end

end

function draw()
    processTouches()
    background(116, 173, 182, 255)
    text("Drag with 1 finger to rotate model on x and y\nDrag 2 fingers to pan\nPinch to track in and out\nRotate 2 fingers to rotate around z")
    FPS=FPS*0.9+0.1/DeltaTime

    perspective() 
    camera(cam.x, cam.y,cam.z, cam.x, cam.y,0)
    pushMatrix()
    
    rotate(rot.z)
    rotate(rot.x,1,0,0)
    rotate(rot.y,0,1,0)

    if model then model:draw() end
    popMatrix()
 
end

function clamp(v,low,high)
    return math.min(math.max(v, low), high)
end

function processTouches()
    local dx,dy = 0,0
    local tArray = {}
    for _,t in pairs(touches) do
        dx = dx + t.deltaX
        dy = dy + t.deltaY
        tArray[#tArray+1] = vec2(t.x, t.y)
    end
    if #tArray == 1 then
        rot.x = rot.x - dy
        rot.y = rot.y + dx
    elseif #tArray == 2 then
        local diff = tArray[2] - tArray[1]
        local pinchDist = diff:len() --tArray[1]:dist(tArray[2])
        local pinchAngle = -math.deg(math.atan(diff.y, diff.x))
        
        local pinchDiff = pinchDist - (lastPinchDist or pinchDist)
        local angleDiff = pinchAngle - (lastPinchAngle or pinchAngle)
        rot.z = rot.z + angleDiff
        
        cam.x = cam.x + dx * cam.z * -0.0005
        cam.y = cam.y - dy * cam.z * -0.0005  
        cam.z = clamp(cam.z + pinchDiff * cam.z * -0.01, -2000, -5)

        lastPinchDist = pinchDist
        lastPinchAngle = pinchAngle
    end
end

function touched(t)
    if t.state == ENDED or t.state == CANCELLED then
        touches[t.id] = nil
        lastPinchDist = nil
        lastPinchAngle = nil
    else
        touches[t.id] = t
    end
end
