# Smart Planar Reflector
By KIP (https://kip.gay)
A simple-to-use and performant 3D planar reflector that provides crystal-clear reflections in complex environments.

## Installation
A. It is recommended to install it through the Asset Library from the Godot Engine.
B. Clone this repository and copy the addon/smart_planar_reflector folder into your project's addons folder

Then, enable the addon from Project -> Plugins.

## Usage
**THIS ADDON WORKS IN SPECIFIC CONFIGURATIONS. PLEASE CHECK THE YOUTUBE VIDEO ON HOW TO USE IT.**
The main thing to note is that the reflector node only works when the mesh is a Godot quad mesh.

## How It Works
Smart Planar Reflector (SPR) is a perspective camera-based planar reflection system. It works by 
creating a camera during runtime that captures what it would look like from the other side of the 
reflection surface.  
**Unlike other planar reflectors**, SPR has a "dynamic near plane" system that will try its best to
cull out anything that's behind the reflection surface from its camera, so that there would be less
obstruction artifacts. However in some cases this is not perfect (especially when there are objects
directly behind the reflection surface), so SPR also provides culling masks. This can effectively
prevent obstruction issues in most environments.

## Optimization
Smart Planar Reflector (SPR) works by using an additional camera (created at runtime) to capture what would the player see from the other side of your reflector.  
This type of reflection, while very versatile, easy-to-setup, and very accurate, has a non-negligable performance cost to your game (render time, **VRAM allocation**)  
SPR provides many systems to help you minimize this performance cost so that it would not dramatically affect the performance of your game.  
**As a general rule, try to make it so that the player would not have more than 2 planar reflectors in view at the same time.**
