extends Area3D

var collisionObjects: Dictionary = {}

@export
var exclude: Array[CollisionObject3D]
var excludeRIDs: Array[RID]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for node in exclude:
		excludeRIDs.append(node.get_rid())

func _physics_process(delta: float) -> void:
	var space_rid = get_world_3d().space
	var space_state = PhysicsServer3D.space_get_direct_state(space_rid)
	
	for node_path in collisionObjects:
		# use global coordinates, not local to node
		var node: Node3D = get_node(node_path)
		
		var query = PhysicsRayQueryParameters3D.create(self.global_position, node.global_position)
		query.exclude = excludeRIDs
		var result = space_state.intersect_ray(query)
		
		var query2 = PhysicsRayQueryParameters3D.create(node.global_position, self.global_position)
		#query2.exclude = excludeRIDs
		var result2 = space_state.intersect_ray(query2)
		collisionObjects[node_path] = {
			"fromArea": { "position": result["position"], "normal": result["normal"] },
			"toArea": { "position": result2["position"], "normal": result2["normal"] }
		}

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	DebugDraw2D.clear_all()
	DebugDraw2D.config.text_default_size = 15
	DebugDraw2D.config.text_background_color = Color.html("202020")
	DebugDraw2D.config.text_padding = Vector2(20, 0)
	var font: Font = load("res://Consolas.ttf")
	DebugDraw2D.config.text_custom_font = font
	
	var fps: DebugDraw2DFPSGraph = DebugDraw2D.create_fps_graph(str(Engine.get_frames_per_second(), " FPS"))
	fps.show_title = true
	
	
	DebugDraw3D.draw_box(position, Quaternion(0,0,0,1), Vector3(2,2,2), Color.LIGHT_BLUE, true, 0)
	
	
	var loop: int = 0
	for node_path in collisionObjects:
		DebugDraw2D.set_text(str(loop, "-0:         "), " ", 0, Color.WHITE, 0)
		DebugDraw2D.set_text(str(loop, "-1: node obj"), node_path, 0, Color.ORANGE, 0)
		#collisionObjects[node_path]["fromArea"]
		DebugDraw2D.set_text(str(loop, "-2:         "), "From Area", 0, Color.BROWN, 0)
		DebugDraw2D.set_text(str(loop, "-3: position"), collisionObjects[node_path]["fromArea"]["position"], 0, Color.AQUA, 0)
		DebugDraw2D.set_text(str(loop, "-4: normal  "), collisionObjects[node_path]["fromArea"]["normal"], 0, Color.AQUAMARINE, 0)
		
		DebugDraw2D.set_text(str(loop, "-5:         "), "To Area", 0, Color.BROWN, 0)
		DebugDraw2D.set_text(str(loop, "-6: position"), collisionObjects[node_path]["toArea"]["position"], 0, Color.AQUA, 0)
		DebugDraw2D.set_text(str(loop, "-7: normal  "), collisionObjects[node_path]["toArea"]["normal"], 0, Color.AQUAMARINE, 0)
		
		DebugDraw3D.draw_points([collisionObjects[node_path]["fromArea"]["position"]], DebugDraw3D.POINT_TYPE_SPHERE, 0.05, Color.DARK_RED, 0)
		DebugDraw3D.draw_points([collisionObjects[node_path]["toArea"]["position"]], DebugDraw3D.POINT_TYPE_SPHERE, 0.05, Color.CHOCOLATE, 0)
		DebugDraw3D.draw_box(position, Quaternion(0,0,0,1), Vector3(2,2,2), Color.CORAL, true, 0)
		loop += 1


func on_body_shape_entered(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	var cache = str(body.get_path())
	collisionObjects[cache] = {}


func on_body_shape_exited(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	var cache = str(body.get_path())
	collisionObjects.erase(cache)
