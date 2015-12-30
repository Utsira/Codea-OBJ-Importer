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
        local filename, ext = name:match("(.-)%.(.-)$") --find name and extension
        if ext == "mtl" or ext == "obj" then --text file
            local file = readText(t.assetPack.path..filename.."_"..ext) --try asset io first
            if file then
                data[i]=file
                print(name, ": ", data[i]:len(), " bytes")
            else --try lua io (nb doesnt work in xcode)
                local path = t.assetPack.io..name
                local file, err = io.open(path, "r")
                if file then
                    data[i]=file:read("*all")
                    print(name, ": ", data[i]:len(), " bytes")
                    file:close()
                else
                    table.insert(missing, name) --add it to roster of files to be requested
                    print("requesting remote file "..name)
                end
            end
        elseif ext == "jpg" or ext == "png" then --image
            local file=readImage(t.assetPack.path..filename)
            if file then
                data[i]=file
            else
                table.insert(missing, name)
                print("requesting remote file "..name)
            end
        end
    end
    
    if #missing > 0 then
        http.requestMany{url = t.url, names = missing, success = t.onRemote}
    else
        t.onLocal(data)
    end    
end

function loadModel1(p)
    local names = {p.name..".mtl", p.name..".obj", p.texture}
    p.assetPack = Dropbox
    readAsset{
        assetPack = Dropbox, 
        url = "https://raw.githubusercontent.com/Utsira/Codea-OBJ-Importer/master/models/", 
        names = names,
        onLocal = function(data) loadModel2(data, p) end, --callback if there is a local copy of file
        onRemote = function(data) loadRemote(data, p, names) end --callback if there is remote copy
    }
end

function loadModel2(data, p)
    p.mtl, p.obj, p.texture = data[1], data[2], data[3]
    model = Mesh{mesh = OBJ.load(p) }
    setView()
end

function loadRemote(data, p, names)
    loadModel2(data, p) --same as load local
    if save_model_to_Dropbox then --but adds option to save data in local dropbox
        for i,v in ipairs(data) do 
            local file, ext = names[i]:match("(.-)%.(.-)$")
            if ext == "mtl" or ext == "obj" then --obj mtl extension not supported so becomes name_obj.txt
                saveText("Dropbox:"..file.."_"..ext, v)
                print("Saving text:", file.."_"..ext)
            elseif ext == "jpg" or ext=="png" then
                saveImage("Dropbox:"..file, v)
                print("Saving image:", file.."."..ext)
            end
            --[[
            local path = Dropbox.io..names[i]
            local file, err = io.open(path, "w")
            if file then
                print("writing "..names[i])
                file:write(v)
                file:close()
            end
              ]]
            -- saveText(Dropbox.path..names[i], v) --savetext doesnt work with obj mtl file extensions
        end
    end
end
