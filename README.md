# Smart Planar Reflector
![img](https://github.com/KipJM/smart_planar_reflector/blob/master/spr_banner.png?raw=true)

A simple-to-use and performant 3D planar reflector Godot plugin that provides crystal-clear reflections in complex environments.

## Installation
1. **(RECOMMENDED) Install "Smart Planar Reflector" through the Asset Library from the Godot Engine.** [LINK](https://godotengine.org/asset-library/asset/4191)
1. (alternative) OR: Clone this repository and copy the addon/smart_planar_reflector folder into your project's addons folder
2. **enable the addon from Project -> Plugins.**

## Demo
### **Watch the Video demo of this plugin here:** [YouTube](https://youtu.be/WUj3DIUBM0E)  
A simple demo scene is in the DEMO folder that demonstrates the basic usage of this addon.  
Please see [ACEDIA](https://kip.gay/acedia) ([source code](https://kip.gay/acedia/repo)) for a full, production-level demonstration of the capabilities of this addon.

## Usage
**THIS ADDON ONLY WORKS IN SPECIFIC CONFIGURATIONS. PLEASE READ BELOW ON HOW TO USE IT.**\
1. Add a planar reflector to your scene by searching for `PlanarReflector` in the Add Node dialog. 
2. Assign a Godot quad primitive to the mesh section of your planar reflector. Then, in the properties of that quad, change the size to how large you want your reflection surface to be.
3. From the Internal/ folder of the addon, create a material using the provided reflection shader. This shader is a VisualShader and you may tweak it to fit your project.
4. Assign the material to the **Material Override 0** slot.
5. Ensure the material is **unique** for each reflector. This is useful when you want multiple meshes in the general area to be all reflective without additional performance cost, but do not reuse reflection materials between reflctors.
6. Enter the NodePath (recommended to be unique!) of your camera into the reflector parameter by right clicking the slot and selecting edit. Alternatively, you may use the camera override attribute.
7. **For performance, planar reflectors are DISABLED by default.** You may attach the `public_enable_mirror()` function to the `ready()` signal to enable it at startup, or you may, for example, only enable it when the player walks into a trigger.
8. `public_` methods are free for you to use to enable, temporaily disable, or free the mirror using signals or code. 

## How It Works
Smart Planar Reflector (SPR) is a perspective camera-based planar reflection system. It works by 
creating a camera during runtime that captures what it would look like from the other side of the 
reflection surface.  
**Unlike other planar reflectors**, SPR has a "dynamic near plane" system that will try its best to
cull out anything that's behind the reflection surface from its camera, so that there would be less
obstruction artifacts. However in some cases this is not perfect (especially when there are objects
directly behind the reflection surface), so SPR also provides culling masks. This can effectively
prevent obstruction issues in most environments.  
Hopefully this won't be needed when "oblique" camera type gets added to Godot.

## Optimization
Smart Planar Reflector (SPR) works by using an additional camera (created at runtime) to capture what would the player see from the other side of your reflector.  
This type of reflection, while very versatile, easy-to-setup, and very accurate, has a non-negligable performance cost to your game (render time, **VRAM allocation**).  
SPR provides many systems to help you minimize this performance cost so that it would not _dramatically_ affect the performance of your game.  
**As a general rule, try to make it so that the player would not have more than 2 planar reflectors in view at the same time.**

## Donation
### If you find this plugin useful, consider donating by **purchasing** my game on itch.io: [ACEDIA](https://kipachu.itch.io/ACEDIA)
