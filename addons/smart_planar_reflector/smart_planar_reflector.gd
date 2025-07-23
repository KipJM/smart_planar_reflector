@tool
extends EditorPlugin


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	add_custom_type("PlanarReflector", "MeshInstance3D", preload("Internal/PlanarReflector.gd"), preload("Internal/PlanarReflector.svg"))


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	remove_custom_type("PlanarReflector")
