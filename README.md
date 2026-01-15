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

## Donation
### If you find this plugin useful, consider donating by **purchasing** my game on itch.io: [ACEDIA](https://kipachu.itch.io/ACEDIA)

## Usage
**THIS ADDON ONLY WORKS IN SPECIFIC CONFIGURATIONS. PLEASE READ BELOW ON HOW TO USE IT.**
1. Add a planar reflector to your scene by searching for `PlanarReflector` in the Add Node dialog. 
2. Assign a Godot quad primitive to the mesh section of your planar reflector. Then, in the properties of that quad, change the size to how large you want your reflection surface to be.
3. Create a material using the provided reflection shader in the Internal/ folder. This shader is a VisualShader. Feel free to tweak it to fit your project.
4. Assign the material to the **Material Override 0** slot.
5. Ensure the material is **unique** for each reflector. If you reuse the same material between objects. Reusing materials is useful when you want multiple meshes in the same general direction to be all reflective without additional performance cost. Do not reuse reflection materials between reflctor scripts, this WILL cause rendering artifacts.
6. Enter the NodePath (recommended to be unique!) of your camera into the reflector parameter by right clicking the slot and selecting edit. Alternatively, you may use the camera override attribute.
7. **For performance, planar reflectors are DISABLED by default.** You may attach the `public_enable_mirror()` function to the `ready()` signal to enable it at startup, or you may, for example, only enable it when the player walks into a trigger.
8. `public_` methods are free for you to use to enable the mirror, temporaily disable the mirror, or free the mirror from memory using signals or code.
9. Feel free to modify the script for your own project. You can find the reflector script in the Internal/ folder, it is fully documented.

## How It Works
Smart Planar Reflector (SPR) is a perspective camera-based planar reflection system. It works by creating a camera during runtime that captures what it would look like from the other side of the reflection surface.

**Unlike other planar reflectors**, SPR has a "dynamic near plane" system that will try its best to cull out anything that's behind the reflection surface from its camera, so that there would be less obstruction artifacts. Since Godot does not support defining an arbitrary culling plane, SPR achieves this by adjusting the near culling plane to the most optimial depth. For the actual algorithm, please see below.

However in some cases this is not perfect (especially when there are objects directly behind the reflection surface), so SPR also provides culling masks. This can effectively prevent obstruction issues in most environments.

Hopefully this won't be needed when "oblique" camera type gets added to Godot.

## Optimization
Smart Planar Reflector (SPR) works by using an additional camera (created at runtime) to capture what would the player see from the other side of your reflector.  
This type of reflection, while very versatile, easy-to-setup, and very accurate, has a non-negligable performance cost to your game (render time, **VRAM allocation**).  
SPR provides many systems to help you minimize this performance cost so that it would not _dramatically_ affect the performance of your game.

**As a general rule, try to make it so that the player would not have more than 2 planar reflectors in view at the same time.**

## Algorithm

![Algorithm Demonstration](https://github.com/KipJM/smart_planar_reflector/blob/master/spr_algo_demo.webp?raw=true)[^note]

[^note]: Algorithm demonstration. The green frustum shows the near clipping plane of the reflector camera. This is a big Webp file (20sec long) so it may lag on your browser when played for the first time.

For the specifics, please view the code. The rough explanation on what the dynamic near plane algorithm does is as follows:

Let the reflection surface be a quad named `R`, the near plane be a quad named `N`. In SPR, These quads will be planar rectangles in 3D space.
> This does not mean your reflection surface must be a rectangle or perfectly flat. The "reflection surface" is used by SPR to only calculate the near plane and view culling. Consider it as a sort of bounding rectangle over your reflective object.

`R` is any arbitrary rectangle in 3D space. It can have any position, rotation or size. `N` is a rectangle constraint by the camera. `N` travels along the reflection camera's forward vector, and its size is determined by the FOV and near plane distance. The reflection camera mirrors the player's camera, which is also posed arbitrarily.

The dynamic near plane system aims to maximize the near plane distance while making sure `R` is always in front of / touching `N`. This may seem simple as first, but remember that both `N` and `R` are bounded, and not infinite planes. This introduces a lot of edge cases *(such as `N`'s surface touching a corner of `R`)*.

SPR solves this by using a collection of test points (vertices of quads, frustum plane corner & reflection intersecitons, edges, etc. basically all intersections of the camera frustum planes with itself and the bounded reflection surface). For each point SPR tests if it is in the camera's view or on the reflection surface. From these "valid" points, the point with the shortest distance to the camera is picked, then its distance is used for the near plane distance.

In other words, SPR ensures the clipping plane will be 100% behind the volume extended infinitely out of the reflection surface. This is achieved by ensuring all the key points on the reflection surface not be clipped out. The near plane is then set to accomodate all of these key points.

This algorithm can find the most optimal ("maximum") near plane distance in every circumstance, for every possible combination of position, rotation or scale of `R` and `N`.
