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
