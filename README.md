# Codea OBJ Importer

An importer to bring 3D models in the popular .obj format into Codea

## To test:

1. Install the Codea OBJ Importer in Codea (copy the entire contents of the /CodeaOBJImporter.lua file to the clipboard. In the Codea projects page, long press "+ add new project" and select "paste into project")
1. Save the files in /models, and any other obj files you want to import, into /Dropbox/Apps/Codea
2. In the Codea asset picker, open Dropbox, and press sync in the topright corner. You'll see a message saying files are being synced, though you won't actually see the files themselves appear in the asset picker, because the extensions .obj and .mtl are not supported by the asset picker. Though this will probably change soon!

## Notes

+ Only supports triangular faces. Select "Triangulate Faces" in the Blender .obj exporter (see /exportSettings.jpg) or apply a triangulate modifier.
+ Expects to find the texture image in the Dropbox. This can be automated by setting "Path Mode" to "Copy" in the Blender .obj exporter (see /exportSettings.jpg)
+ Currently, the importer only supports models with a single image texture, but models could have multiple textures. Previous implementations have addressed this by splitting the imported model according to its material. This is not a satisfactory solution however, as models could have multiple materials with the same (or no) image texture (as in the Tank.obj example). 2 potential approaches:
	 1. Split the blender model into separate objects for each image texture. These separate objects would still be contained in a single obj file, and are flagged with the "o" code. The importer would start a new object when it sees "o". This would mean the user would have to split models that contain multiple textures (in Blender edit mode, tap "a" to deselect all, select the material, press "select" to select the geometry that have that material, press "p" for separate, click "selection"), and join objects that have no texture or share the same texture (select the two objects, hit "j" for join). This would also allow the user to split objects for animation purposes (eg separate the wheels from the body of a vehicle)
	 2. Have the importer analyse the material list, and only split the object if a material uses a different texture.
	 3. Both of the above.

