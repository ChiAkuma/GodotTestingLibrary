extends Area3D

var collisionData: Dictionary = {}
#var body: Node3D = null
#var body_shape_index = -1

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _physics_process(delta: float) -> void:
	for node_path in collisionData:
		var body: RigidBody3D = get_node(node_path)
		if (body == null): return
		print("Body entered:", body.name)
		print("Body", body.get_path())
		
		# Get the space of the current area.
		var area_space: RID = PhysicsServer3D.area_get_space(get_rid())
		var space_state: PhysicsDirectSpaceState3D = PhysicsServer3D.space_get_direct_state(area_space)
		
		# Retrieve the shape from the body.
		#var shape_owner_id = body.shape_owner_get_owner(body_shape_index)
		#var shape: Shape3D = body.shape_owner_get_shape(shape_owner_id, 0)
		
		var shape: Shape3D = body.shape_owner_get_shape(0, 0)
		
		if shape == null:
			print("Error: No valid shape found.")
			return
		
		# Create and set up the query parameters.
		var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
		query.shape_rid = shape.get_rid()
		query.transform = body.transform
		query.collision_mask = 0xFFFFFFFF  # Collide with all layers for debugging purposes
		
		# Execute the collision query.
		var collision_points = space_state.collide_shape(query)
		print(collision_points)
		
		# Process and print the collision points.
		if collision_points.size() > 0:
			print("Collision points found:", collision_points)
			collisionData[body.get_path()]["points"] = collision_points
		else:
			print("No collision points found.")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	DebugDraw2D.config.text_default_size = 15
	DebugDraw2D.set_text("0", "Working Debugging tool")
	
	DebugDraw3D.draw_box(position, Quaternion(0,0,0,1), Vector3(2,2,2), Color.LIGHT_BLUE, true, 0)
	var loop: int = 0
	for node_path in collisionData:
		var body: RigidBody3D = get_node(node_path)
		DebugDraw2D.set_text(str(loop, "-1:", node_path), collisionData[node_path], 0, Color.AQUA, 0)
		DebugDraw3D.draw_box(position, Quaternion(0,0,0,1), Vector3(2,2,2), Color.CORAL, true, 0)
		
		#DebugDraw3D.draw_points([collisionData[node_path]["point"]], DebugDraw3D.POINT_TYPE_SPHERE, 0.05, Color.MEDIUM_VIOLET_RED)
		
		if (len(collisionData[node_path]["points"]) > 0):
			DebugDraw3D.draw_points([collisionData[node_path]["points"][0]], DebugDraw3D.POINT_TYPE_SPHERE, 0.05, Color.DARK_RED)
			DebugDraw3D.draw_points([collisionData[node_path]["points"][1]], DebugDraw3D.POINT_TYPE_SPHERE, 0.05, Color.ORANGE)
		loop += 1

func on_body_shape_entered(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	#self.body = body
	#self.body_shape_index = body_shape_index
	self.collisionData[body.get_path()] = {}
	pass


func on_body_shape_exited(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	#self.body = null
	#self.body_shape_index = -1
	self.collisionData.erase(body.get_path())
	pass # Replace with function body.
