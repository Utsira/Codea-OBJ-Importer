# Codea OBJ Importer

An importer to bring 3D models in the popular .obj format into Codea

## Screenshots

![character](https://raw.githubusercontent.com/Utsira/Codea-OBJ-Importer/master/screenshots/character.png)

![island](https://raw.githubusercontent.com/Utsira/Codea-OBJ-Importer/master/screenshots/island.png)

![robot](https://raw.githubusercontent.com/Utsira/Codea-OBJ-Importer/master/screenshots/asset.jpg)

![wireframe mode](https://raw.githubusercontent.com/Utsira/Codea-OBJ-Importer/master/screenshots/asset-2.jpg)

![thick wireframe](https://raw.githubusercontent.com/Utsira/Codea-OBJ-Importer/master/screenshots/wireframe.jpg)

## To install:

1. Install the Codea OBJ Importer in Codea (copy the entire contents of the /Codea OBJ Importer Installer.lua file to the clipboard. In the Codea projects page, long press "+ add new project" and select "paste into project")
1. Save the model files in /models, and any other obj files you want to import, into /Dropbox/Apps/Codea
2. In the Codea asset picker, open Dropbox, and press sync in the top-right corner. You'll see a message saying files are being synced, though you won't actually see the files themselves appear in the asset picker, because the extensions .obj and .mtl are not supported by the asset picker (though support for these extensions appears to be coming to Codea soon).

## Rationale

This is adapted from Ignatz's obj importer via my keyframe interpolator, but makes a number of changes compared to these:

+ It uses Dropbox rather than asynchronous http loading. This greatly simplifies the workflow and loading process, particularly when working with multiple files, as you can just load the files in order, rather than waiting for a response from the server. It means you can export from Blender straight into your Dropbox, hit sync in the Dropbox folder in Codea, and run the code again. This also makes it easy to export your 3D project for Xcode
+ It is designed to use the exported files as-is, without making any changes to them, speeding up the Blender-to-Codea workflow. Note that textures images will also have to be in Dropbox. Blender can do this for you automatically on export with the Path mode:copy setting (see export settings below)
+ Objects are not split into multiple meshes depending on material, although currently this means that only one texture image is supported per model (see notes below). I decided to set it up this way for a couple of reasons:
    1. As described below, a model can have many materials that use the same image, or don't use an image at all (as seen in the example models here). 
    2. In order to get as much geometry as possible onto a single mesh, to minimise the number of draw calls, which is key to getting decent 3D performance out of Codea. In general then, try to pack all of the images you need into a single jpeg (a texture atlas). Note that large texture images (relatively uncompressed pngs etc) can also have a negative impact on performance.
+ File io/parsing is kept separate from model display (shading/ lighting etc). The model loader (OBJ tab) is separated from the model display and shading class (Mesh tab). This is because you frequently want to reuse the same mesh lots of times in a scene. ie if you have an army of tanks, you would only load and process Tank.obj once. Then, you would have lots of tank instances using the Mesh class to track the various positions, orientations, lighting conditions of each tank instance (but you don't copy the tank geometry, only one copy of the geometry exists in memory, and drawn repeatedly). This also means that game objects do not have file io methods that they don't need.

## Exporting from Blender

+ Only supports triangular faces. Select "Triangulate Faces" in the Blender .obj exporter (see image below) or apply a triangulate modifier.
    ![export setting](https://raw.githubusercontent.com/Utsira/Codea-OBJ-Importer/master/Blender%20export%20settings.jpg)
+ Expects to find the texture image in the Dropbox. This can be automated by setting "Path Mode" to "Copy" in the Blender .obj exporter (see image above). Note that you can save export presets, so that you can save with consistent settings.
+ Currently, the importer only supports models with a single texture image (see below), 

## Issues

Currently, the importer only supports models with a single image texture. However models can have multiple texture images. Previous implementations have addressed this by splitting the imported model according to its material. This is not a satisfactory solution however, as models could have multiple materials with the same (or no) image texture (as in the example models in this repo). 2 potential approaches:
	 1. Have the user split and join the blender model into separate objects for each image texture. These separate objects would still be contained in a single obj file, and are flagged with the "o" code. The importer would start a new object when it sees "o". This would mean the user would have to split models that contain multiple textures (in Blender edit mode, tap "a" to deselect all, select the material, press "select" to select the geometry that have that material, press "p" for separate, click "selection"), and join objects that have no texture or share the same texture (select the two objects, hit "j" for join). This would also allow the user to split objects for animation purposes (eg separate the wheels from the body of a vehicle)
	 2. Have the importer analyse the material list, and only split the object if a material uses a different texture.
	 3. Both of the above.
