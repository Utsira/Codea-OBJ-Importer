http.requestMany = class() --request multiple remote files, callback is triggered when all load

function http.requestMany:init(t) --url path to raw data, names of each file, success callback (required), fail callback (optional)
    self.success = t.success
    self.fail = t.fail or function() end
    self.names = t.names
    self.data = {}
    self.completed = {}
    for i,v in ipairs(self.names) do
        http.request(t.url..v, function(data) self:fileLoaded(data, i) end, function(error) self:fileFailed(error, i) end)
    end
    
end

function http.requestMany:fileLoaded(data, i)
    self.data[i] = data
    self.completed[i] = true
    self:consolidate()
end

function http.requestMany:fileFailed(error, i)
    self.completed[i] = true
    self.error = error
    self:consolidate()
end

function http.requestMany:consolidate()
    if #self.data == #self.names then
        self.success(self.data)
    elseif #self.completed == #self.names then
        alert(self.error) --i.."/"..#self.names.." failed",
        self.fail(self.data, self.error)
    end
end
