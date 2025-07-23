# IF YOU HAVE DebugDraw3D installed, you may uncomment the #DEBUG lines to enable debug capabilities
class_name PlanarReflector
extends MeshInstance3D

@export_group("Main Camera")
## The path to the main camera. I recommend changing the default value in the script to a unique node path so you don't have to set this every time.
@export var camera_path: NodePath = "%Camera"
## If non-empty, the reflector will use this camera as the main camera instead of camera_path
@export var camera_override: Camera3D = null # Camera override

@export_group("Display")
## Scaling factor of the main viewport's resolution that will be the reflection's resolution, usually between 0 to 1.
@export var resolution_scale: float = 1
## Distance of the reflector camera's far clipping plane.
@export var far: float = 4000
## If set, this will override the reflection's environment (default to main camera's environment or the global environment).
@export var custom_environment: Environment = null
## If set, this will override the reflector camera's camera attributes (default to None).
@export var custom_attributes: CameraAttributes = null
## This render layer will be visible in the reflection regardless of the main camera's render mask. Set to -1 to ignore.
@export var render_enable_layer: int = 20
## This render layer will be invisible in the reflection regardless of the main camera's render mask. Set to -1 to ignore.
@export var render_disable_layer: int = 19

@export_group("Debug")
## Enable debug features. You need to install DebugDraw3D and uncomment the "#DEBUG" lines for most of the debug functionality.
@export var debug_enabled: bool = false
## The reflector camera's rendertexture will be displayed on the TextureRect for debugging, requires debug_enabled = true.
@export var debug_ui: TextureRect
## Drag the camera_frustum_debug.gd script here to show reflector camera's debug visualization. Requires DebugDraw3D. Requries debug_enabled = true.
@export var debug_frustum_script: GDScript


# Private variables. Do not modify these internal variables from outside of this script.
var reflect_camera: Camera3D
var reflect_viewport: SubViewport

var _main_camera: Camera3D;

var reflection_enabled:bool = false

var initialized:bool = false

## PRIVATE method to allocate VRAM and ready the reflector for reflections.
func init_mirror():	
	update_camera()
	
	# Create the subviewport and camera to render the reflection. This also allocates the required VRAM.
	reflect_viewport = SubViewport.new();
	add_child(reflect_viewport);
	reflect_camera = Camera3D.new();
	reflect_viewport.add_child(reflect_camera);
	reflect_viewport.audio_listener_enable_3d = false
	
	# Setup cullmask.
	reflect_camera.cull_mask = _main_camera.cull_mask;
	if render_enable_layer != -1:
		reflect_camera.set_cull_mask_value(render_enable_layer, true)
	if render_disable_layer != -1:
		reflect_camera.set_cull_mask_value(render_disable_layer, false)

	# setup environment & camera attributes
	if custom_environment != null:
		reflect_camera.environment = custom_environment
	else:
		# If this is also null, Godot will automatically apply the global environment to this camera.
		reflect_camera.environment = _main_camera.environment
	
	if custom_attributes != null:
		reflect_camera.attributes = custom_attributes
	
	# default settings that should not be changed. The doppler tracking one just increases performance a bit.
	reflect_camera.doppler_tracking = Camera3D.DOPPLER_TRACKING_DISABLED
	reflect_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	reflect_camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	
	# Start rendering.
	reflect_camera.make_current()

	# Attaches the render texture to the material.
	var mat:ShaderMaterial = self.get_surface_override_material(0)
	if mat == null:
		printerr("Reflection material not correctly set on reflector, reflector won\' function!")
		print("Reflection material needs to be set on the 0 slot of the surface material override section of the reflector.")
		return
		
	if not mat.get_property_list().any(func o(x): return x.name == "shader_parameter/reflection_texture"):
		printerr("Material is not using reflector-compatible shader, reflections won\'t be visible!")
	mat.set_shader_parameter("reflection_texture", reflect_viewport.get_texture());
	
	
	# debug features.
	if debug_enabled:
		if debug_ui != null:
			debug_ui.texture = reflect_viewport.get_texture()
		
		if debug_frustum_script != null:
			reflect_camera.set_script(debug_frustum_script);
			reflect_camera.set_process(true);
	
	# Update reflection resolution.
	update_viewport()
	initialized = true;

## PRIVATE Method to choose the main camera
func update_camera() -> void:
	if (camera_override == null):
	# Auto find camera from player
		_main_camera = get_node(camera_path)
	else:
		_main_camera = camera_override;
	
	if _main_camera == null:
		printerr("Main camera not found for planar reflector, expect a lot of errors.")

## PRIVATE Method to update the reflection resolution & other settings. This is ran per-frame so you may change the main_camera, adjust the main camera's fov, resolution_scale and far plane on-the-fly.
func update_viewport() -> void:
	update_camera()
	
	reflect_viewport.size = get_viewport().size * resolution_scale
	
	reflect_camera.fov = _main_camera.fov
	reflect_camera.far = far # Arbitrary

	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if (!reflection_enabled):
		return
	
	# You need a main camera to reflect
	if (!get_node(camera_path) and !camera_override):
		return
	
	update_viewport()
	
	# Update reflection.
	if update_reflect_cam():
		reflect_camera.make_current() # Reflection may be in view. (Since occlusion is not accounted for)
	else:
		reflect_camera.clear_current() # Reflection is 100% not in view.
	
## PRIVATE method to update the reflector camera's position, rotation, and adjusts the dynamic near plane.
## Why dynamic near plane instead of frustum mode? Because frustum mode has anti-aliasing artifacts, slow speed and most importantly inefficient resolution mapping because of the inverse square law.
## This function returns false when the reflection surface is not in view of the player.
func update_reflect_cam() -> bool:
	# So the math here was written at 3AM or something. It works very well but I really can't explain fully how it works now lol.
	
	# Main references, we're using Godot's plane class for the position and rotation cacluations
	var reflection_transform = global_transform;
	var plane_origin = reflection_transform.origin;
	var plane_normal = reflection_transform.basis.z.normalized();
	var reflection_plane = Plane(plane_normal, plane_origin.dot(plane_normal))
	
	var cam_pos = _main_camera.global_position
	
	var proj_pos := reflection_plane.project(cam_pos)
	var mirrored_pos = cam_pos + (proj_pos - cam_pos) * 2.0
	
	# Set location
	reflect_camera.global_transform.origin = mirrored_pos;
	
	# Set rotation
	reflect_camera.basis = Basis(
		_main_camera.global_basis.x.normalized().bounce(reflection_plane.normal).normalized(),
		_main_camera.global_basis.y.normalized().bounce(reflection_plane.normal).normalized(),
		_main_camera.global_basis.z.normalized().bounce(reflection_plane.normal).normalized()
	)
	
	# safety check
	if mesh == null:
		printerr("A primitive Quad mesh needs to be assigned to the planar reflector for it to work! Use the size parameter to change the dimensions of your reflection surface.")
		return false
		
	if "size" not in mesh:
		printerr("Mesh for the planar reflector has to be a Godot primitive quad! Use the size parameter to change the dimensions of your reflection surface.")
		return false
		
	#==  Dynamic near plane calculation a.k.a. Hell, this is the part that was written at 3AM
	# The basic idea is to find the furthese point the near plane can reach without clipping into the reflection surface
	# In other words, it MUST NOT clip out anything infront of the reflection surface while clipping out as much as possible behind it.
		
	var camera_planes = reflect_camera.get_frustum();
	var right_plane   = camera_planes[4] # from player's right
	var left_plane  = camera_planes[2] # from player's left
	var top_plane    = camera_planes[3]
	var bottom_plane = camera_planes[5]
	
	# mesh points (for high accuracy dynamic near and frustum culling)
	var mesh_size_half = Vector3(mesh.size.x/2, mesh.size.y/2, 0)
	var mesh_bl = to_global(Vector3(-mesh_size_half.x, -mesh_size_half.y, 0)) # yaoi
	var mesh_br = to_global(Vector3( mesh_size_half.x, -mesh_size_half.y, 0))
	var mesh_tl = to_global(Vector3(-mesh_size_half.x,  mesh_size_half.y, 0))
	var mesh_tr = to_global(Vector3( mesh_size_half.x,  mesh_size_half.y, 0))
	
	# plane points (arghh I don't even) 
	var point_bl = bottom_plane.intersects_segment(mesh_bl, mesh_tl)
	var point_br = bottom_plane.intersects_segment(mesh_br, mesh_tr)
	var point_tl = top_plane.intersects_segment(mesh_bl, mesh_tl)
	var point_tr = top_plane.intersects_segment(mesh_br, mesh_tr)
	
	var point_lb = left_plane.intersects_segment(mesh_bl, mesh_br)
	var point_lt = left_plane.intersects_segment(mesh_tl, mesh_tr)
	var point_rb = right_plane.intersects_segment(mesh_bl, mesh_br)
	var point_rt = right_plane.intersects_segment(mesh_tl, mesh_tr)
	
	var corner_bl = reflection_plane.intersect_3(bottom_plane, left_plane)
	var corner_br = reflection_plane.intersect_3(bottom_plane, right_plane)
	var corner_tl = reflection_plane.intersect_3(top_plane, left_plane)
	var corner_tr = reflection_plane.intersect_3(top_plane, right_plane)
	
	var check_point_in_view = func(point: Vector3): 
		# meet at least three
		if top_plane.is_point_over(point): 
			if !top_plane.has_point(point):
				return false;
		if bottom_plane.is_point_over(point):
			if !bottom_plane.has_point(point):
				return false;
		if left_plane.is_point_over(point):
			if !left_plane.has_point(point):
				return false;
		if right_plane.is_point_over(point):
			if !right_plane.has_point(point):
				return false;
		
		return true;
		
	var check_point_in_mesh = func(point: Vector3):
		var point_local = to_local(point)
		return ((-mesh_size_half.x < point_local.x && point_local.x < mesh_size_half.x) &&
		(-mesh_size_half.y < point_local.y && point_local.y < mesh_size_half.y))
	
	
	var point_vectors: Array[Vector3];

	var point_list = [point_bl, point_br, point_tl, point_tr, point_lb, point_lt, point_rb, point_rt, 
		mesh_bl, mesh_br, mesh_tl, mesh_tr]
	for i in len(point_list):
		var point = point_list[i]
		if !point:
			continue
			
		var point_vector: Vector3 = reflect_camera.to_local(point);
		if check_point_in_view.call(point) && -point_vector.z > 0:
			point_vectors.append(point_vector);
			
		# DEBUG Start: DebugDraw3D required.
			#if debug_enabled:
				#DebugDraw3D.draw_points([point], DebugDraw3D.POINT_TYPE_SQUARE, 0.2, Color.GREEN)
			
		#else:
			#if debug_enabled:
				#DebugDraw3D.draw_points([point], DebugDraw3D.POINT_TYPE_SQUARE, 0.2, Color.RED)
		
		#if debug_enabled:
			#DebugDraw3D.draw_text(point - Vector3.FORWARD * 0.1, [
				#"point_bl", "point_br", "point_tl", "point_tr", "point_lb", "point_lt", "point_rb", "point_rt", 
				#"mesh_bl", "mesh_br", "mesh_tl", "mesh_tr", 
				#"corner_bl", "corner_br", "corner_tl", "corner_tr"][i])
		# DEBUG End
	
	
	var corner_list = [corner_bl, corner_br, corner_tl, corner_tr]
	for i in len(corner_list):
		var point = corner_list[i]
		if !point:
			continue
		
		var point_vector: Vector3 = reflect_camera.to_local(point);
		if check_point_in_mesh.call(point) && -point_vector.z > 0:
			point_vectors.append(point_vector);
		
		# DEBUG Start: DebugDraw3D required.
			#if debug_enabled:
				#DebugDraw3D.draw_points([point], DebugDraw3D.POINT_TYPE_SQUARE, 0.2, Color.GREEN)
		#else:
			#if debug_enabled:
				#DebugDraw3D.draw_points([point], DebugDraw3D.POINT_TYPE_SQUARE, 0.2, Color.RED)
		#
		#if debug_enabled:
			#DebugDraw3D.draw_text(point - Vector3.FORWARD * 0.1, ["corner_bl", "corner_br", "corner_tl", "corner_tr"][i])
		# DEBUG End
	
	if len(point_vectors) < 1:
		return false# not in view
	
	# Find shortest near plane that doesn't remove any content
	point_vectors.sort_custom(func(a: Vector3, b: Vector3): return -a.z < -b.z)
	var target_vector = point_vectors[0]
	
	# DEBUG Start: DebugDraw3D required.
	#if debug_enabled:
		#DebugDraw3D.draw_arrow_ray(reflect_camera.global_position, (reflect_camera.global_basis.inverse() * target_vector), 1, Color.WHITE, 0.2)
	# DEBUG End
	
	reflect_camera.near = -target_vector.z
	return true
	#==

# ======= PUBLIC FUNCTIONS ====== #

## PUBLIC Function to enable the reflector and start reflecting. Will automatically initialize the mirror if it didn't initialize.
func public_enable_mirror() -> void:
	if (!initialized):
		init_mirror()
	
	if (!reflection_enabled): # Enable cam
		#print("Seen!")
		reflection_enabled = true;
	
## PUBLIC Function to temporairly disable the reflector to improve performance. However VRAM is still allocated.
func public_disable_mirror() -> void:
	if(reflection_enabled): 
		#print("Clear")
		# Stop camera to save compute resources
		# Unfortunately VRAM is still needed :O
		# Unallocating/allocating takes too much time :|
		reflect_camera.clear_current()
		reflection_enabled = false;

## PUBLIC Function to permanantely destroy the reflector and free its VRAM allocation.
func public_destroy_mirror() -> void:
	public_disable_mirror()
	#print("DESTROY MIRROR")
	if (initialized):
		reflect_camera.queue_free()
		reflect_viewport.queue_free()
	
## Helper signal receivers to easily enable the reflector when the player walks into an Area3D.
func _public_on_enabler_entered(_body: Node3D) -> void:
	public_enable_mirror()

## Helper signal receivers to easily disable the reflector when the player walks out of an Area3D.
func _public_on_enabler_exited(_body: Node3D) -> void:
	public_disable_mirror()
