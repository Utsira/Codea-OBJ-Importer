--readAsset
 
Dropbox = {
    path = "Dropbox:", --path for assets
    io = os.getenv("HOME").."/Documents/Dropbox.assets/" --same path for files not recognised as assets. assetpack
}

Documents = {
    path = "Documents:",
    io = os.getenv("HOME").."/Documents/Documents.assets/" --same path for files not recognised as assets. 
}

function readAsset(t) --(assetPack, url, names, onLocal, onRemote)
    --attempt to open file
    local data = {} 
    local missing = {}
    
    for i,name in ipairs(t.names) do
        local path = t.assetPack.io..name
        local file, err = io.open(path, "r")
        if file then
            data[i]=file:read("*all")
            print(name, ": ", data[i]:len(), " bytes")
            file:close()    
        else 
            table.insert(missing, name)
            print("requesting missing file "..name)
        end
    end
    
    if #missing > 0 then
        http.requestMany{url = t.url, names = missing, success = t.onRemote}
    else
        t.onLocal(data)
    end    
end

function loadModel1(p)
    local names = {p.name..".mtl", p.name..".obj"}
    readAsset{
        assetPack = Dropbox, 
        url = "https://raw.githubusercontent.com/Utsira/Codea-OBJ-Importer/master/models/", 
        names = names,
        onLocal = function(data) loadModel2(data, p) end, --callback if there is a local copy of file
        onRemote = function(data) loadRemote(data, p, names) end --callback if there is remote copy
    }
end

function loadModel2(data, p)
    p.mtl, p.obj = data[1], data[2]
    model = Mesh{mesh = OBJ.load(p) }
    setView()
end

function loadRemote(data, p, names)
    loadModel2(data, p) --same as load local
    if save_model_to_Dropbox then --but adds option to save data in local dropbox
        for i,v in ipairs(data) do 
            local path = Dropbox.io..names[i]
            local file, err = io.open(path, "w")
            if file then
                print("writing "..names[i])
                file:write(v)
                file:close()
            end
            -- saveText(Dropbox.path..names[i], v) --savetext doesnt work with obj mtl file extensions
        end
    end
end
