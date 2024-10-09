extends Area3D

##[codeblock json]
##{
##    "fromArea": {
##        "position": Vector3,
##        "normal": Vector3
##    },
##    "toArea": {
##        "position": Vector3,
##        "normal": Vector3
##    },
##    "straightRaysResults": {
##        "Up": {
##            "position": Vector3,
##            "normal": Vector3
##        },
##        "Down": {
##            "position": Vector3,
##            "normal": Vector3
##        },
##        "Back": {
##            "position": Vector3,
##            "normal": Vector3
##        },
##        "Forward": {
##            "position": Vector3,
##            "normal": Vector3
##        },
##        "Right": {
##            "position": Vector3,
##            "normal": Vector3
##        },
##        "Left": {
##            "position": Vector3,
##            "normal": Vector3
##        }
##    }
##}
##[/codeblock]
##You could also see something like this:
##[codeblock json]
##"straightRaysResults": {
##    "Up": null,
##	...
##}
##[/codeblock]
var collisionObjects: Dictionary = {}
"""

"""

enum Direction {UP, DOWN, BACK, FORWARD, RIGHT, LEFT}

var direction_names = {
	Direction.UP: "UP",
	Direction.DOWN: "DOWN",
	Direction.BACK: "BACK",
	Direction.FORWARD: "FORWARD",
	Direction.RIGHT: "RIGHT",
	Direction.LEFT: "LEFT"
}

@export
var exclude: Array[CollisionObject3D]
var excludeRIDs: Array[RID]

var parent: Node3D
var realCubeNormals

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.parent = get_parent()
	self.realCubeNormals = [parent.transform.basis.y, -parent.transform.basis.y, parent.transform.basis.z, -parent.transform.basis.z, parent.transform.basis.x, -parent.transform.basis.x]
	for node in exclude:
		excludeRIDs.append(node.get_rid())

func _physics_process(_delta: float) -> void:
	var space_rid: RID = get_world_3d().space
	var space_state: PhysicsDirectSpaceState3D = PhysicsServer3D.space_get_direct_state(space_rid)
	
	self.realCubeNormals = [parent.transform.basis.y, -parent.transform.basis.y, parent.transform.basis.z, -parent.transform.basis.z, parent.transform.basis.x, -parent.transform.basis.x]
	
	for node_path in collisionObjects:
		if node_path == "default": break
		# use global coordinates, not local to node
		var node: CollisionObject3D = get_node(node_path)
		
		var fromAreaQuery = PhysicsRayQueryParameters3D.create(self.global_position, node.global_position)
		fromAreaQuery.exclude = excludeRIDs
		var fromAreaResult = space_state.intersect_ray(fromAreaQuery)
		
		
		var toAreaQuery = PhysicsRayQueryParameters3D.create(node.global_position, self.global_position)
		var toAreaResult = space_state.intersect_ray(toAreaQuery)
		# [Vector3.UP, Vector3.DOWN, Vector3.BACK, Vector3.FORWARD, Vector3.RIGHT, Vector3.LEFT]
		
				#Data Collection Dictionary
		collisionObjects[node_path] = {
			"fromArea":    { "position": fromAreaResult["position"], "normal": fromAreaResult["normal"] },
			"toArea":      { "position": toAreaResult["position"], "normal": toAreaResult["normal"] },
			"straightRaysResults": {
				"UP":      null,
				"DOWN":    null,
				"BACK":    null,
				"FORWARD": null,
				"RIGHT":   null,
				"LEFT":    null
			}			
		}
		
		#raycasts
		var from: Vector3 = fromAreaResult["position"]
		var rayRange: float = 5
		#raycast up
		raycast(space_state, node_path, [node.get_rid()], from, rayRange, Direction.UP)
		
		#raycast down
		raycast(space_state, node_path, [node.get_rid()], from, rayRange, Direction.DOWN)
		
		#raycast back
		raycast(space_state, node_path, [node.get_rid()], from, rayRange, Direction.BACK)
		
		#raycast forward
		raycast(space_state, node_path, [node.get_rid()], from, rayRange, Direction.FORWARD)
		
		#raycast right
		raycast(space_state, node_path, [node.get_rid()], from, rayRange, Direction.RIGHT)
		
		#raycast left
		raycast(space_state, node_path, [node.get_rid()], from, rayRange, Direction.LEFT)

## Raycast function
func raycast(space_state: PhysicsDirectSpaceState3D, node_path: String, exclude: Array[RID], from: Vector3, length: float, side: int) -> void:
	#[Vector3.UP, Vector3.DOWN, Vector3.BACK, Vector3.FORWARD, Vector3.RIGHT, Vector3.LEFT]
	var sideVector: Vector3 = realCubeNormals[side]
	var to: Vector3 = from + sideVector * length
	
	var raycast = PhysicsRayQueryParameters3D.create(from, to)
	raycast.exclude = exclude
	var raycastResult: Dictionary = space_state.intersect_ray(raycast)
	
	if (raycastResult != null and raycastResult != {}):
		self.collisionObjects[node_path]["straightRaysResults"][direction_names[side]] = { "position": raycastResult["position"], "normal": raycastResult["normal"] }
	else:
		self.collisionObjects[node_path]["straightRaysResults"][direction_names[side]] = { "position": to, "normal": "keine" }

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	DebugDraw2D.clear_all()
	DebugDraw2D.config.text_default_size = 14
	#DebugDraw2D.config.text_default_size = 25
	DebugDraw2D.config.text_background_color = Color.html("202020")
	DebugDraw2D.config.text_padding = Vector2(20, 0)
	var font: Font = load("res://Consolas.ttf")
	DebugDraw2D.config.text_custom_font = font
	
	DebugDraw3D.config.visible_instance_bounds = false
	DebugDraw3D.config.use_frustum_culling = false
	DebugDraw3D.config.force_use_camera_from_scene = false
	#DebugDraw3D.config.
	
	var fps: DebugDraw2DFPSGraph = DebugDraw2D.create_fps_graph(str(Engine.get_frames_per_second(), " FPS"))
	fps.show_title = true
	
	DebugDraw3D.draw_box(position, parent.quaternion, Vector3(2,2,2), Color.LIGHT_BLUE, true, 0)

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
		DebugDraw3D.draw_box(position, parent.quaternion, Vector3(2,2,2), Color.CORAL, true, 0)
		calculateCoordinate(loop, node_path, get_node(node_path), collisionObjects[node_path]["fromArea"]["position"], self, collisionObjects[node_path]["toArea"]["position"])
		loop += 1

## This is very cooooool
func calculateCoordinate(textIndentifier: int, node_path: String, player: RigidBody3D, playerRayResult: Vector3, areaDetector: Area3D, cubeRayResult: Vector3) -> void:
	DebugDraw2D.set_text(str(textIndentifier, "-9:         "), " ", 0, Color.WHITE, 0)
	DebugDraw2D.set_text(str(textIndentifier, "-10         "), "Calculate Coordinate System", 0, Color.BISQUE, 0)
	
	#standart normals that should be if the object is NOT rotated
	var standardCubeNormals = [Vector3.UP, Vector3.DOWN, Vector3.BACK, Vector3.FORWARD, Vector3.RIGHT, Vector3.LEFT]
	DebugDraw2D.set_text(str(textIndentifier, "-11 stdnorm "), str(standardCubeNormals), 0, Color.CORNFLOWER_BLUE, 0)
	#------------------------------------------------------------
	#get parent rotation and then the up, down, back, forward, right and left vectors
	#this accounts for the rotation of the object
	DebugDraw2D.set_text(str(textIndentifier, "-12 parent  "), str(parent), 0, Color.CORNFLOWER_BLUE, 0)
	DebugDraw2D.set_text(str(textIndentifier, "-13 facenorm"), str(realCubeNormals), 0, Color.MEDIUM_PURPLE, 0)
	#------------------------------------------------------------
	#send raycasts in these directions
	DebugDraw2D.set_text(str(textIndentifier, "-14         "), "6 Raycasts", 0, Color.BISQUE, 0)
	DebugDraw2D.set_text(str(textIndentifier, "-15 up      "), str(collisionObjects[node_path]["straightRaysResults"]["UP"]), 0, Color.MEDIUM_PURPLE, 0)
	DebugDraw2D.set_text(str(textIndentifier, "-16 down    "), str(collisionObjects[node_path]["straightRaysResults"]["DOWN"]), 0, Color.MEDIUM_PURPLE, 0)
	DebugDraw2D.set_text(str(textIndentifier, "-17 back    "), str(collisionObjects[node_path]["straightRaysResults"]["BACK"]), 0, Color.MEDIUM_PURPLE, 0)
	DebugDraw2D.set_text(str(textIndentifier, "-18 forward "), str(collisionObjects[node_path]["straightRaysResults"]["FORWARD"]), 0, Color.MEDIUM_PURPLE, 0)
	DebugDraw2D.set_text(str(textIndentifier, "-19 right   "), str(collisionObjects[node_path]["straightRaysResults"]["RIGHT"]), 0, Color.MEDIUM_PURPLE, 0)
	DebugDraw2D.set_text(str(textIndentifier, "-20 left    "), str(collisionObjects[node_path]["straightRaysResults"]["LEFT"]), 0, Color.MEDIUM_PURPLE, 0)
	
	var directionPoints: Array[Vector3]
	if (collisionObjects[node_path]["straightRaysResults"]["UP"] != null):
		directionPoints.append(collisionObjects[node_path]["straightRaysResults"]["UP"]["position"])
	if (collisionObjects[node_path]["straightRaysResults"]["DOWN"] != null):
		directionPoints.append(collisionObjects[node_path]["straightRaysResults"]["DOWN"]["position"])
	if (collisionObjects[node_path]["straightRaysResults"]["BACK"] != null):
		directionPoints.append(collisionObjects[node_path]["straightRaysResults"]["BACK"]["position"])
	if (collisionObjects[node_path]["straightRaysResults"]["FORWARD"] != null):
		directionPoints.append(collisionObjects[node_path]["straightRaysResults"]["FORWARD"]["position"])
	if (collisionObjects[node_path]["straightRaysResults"]["RIGHT"] != null):
		directionPoints.append(collisionObjects[node_path]["straightRaysResults"]["RIGHT"]["position"])
	if (collisionObjects[node_path]["straightRaysResults"]["LEFT"] != null):
		directionPoints.append(collisionObjects[node_path]["straightRaysResults"]["LEFT"]["position"])
	
	DebugDraw2D.set_text(str(textIndentifier, "-21         "), str(len(directionPoints)), 0, Color.CORNFLOWER_BLUE, 0)
	DebugDraw3D.draw_points(directionPoints, DebugDraw3D.POINT_TYPE_SPHERE, 0.1, Color.PURPLE, 0)
	DebugDraw3D.draw_points([Vector3 (10, 10, 10)], DebugDraw3D.POINT_TYPE_SPHERE, 0.1, Color.PURPLE, 0)
	DebugDraw2D.set_text(str(textIndentifier, "-22         "), str("coming soon..."), 0, Color.CORNFLOWER_BLUE, 0)
 
func on_body_shape_entered(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	var cache = str(body.get_path())
	collisionObjects[cache] = {}


func on_body_shape_exited(body_rid: RID, body: Node3D, body_shape_index: int, local_shape_index: int) -> void:
	var cache = str(body.get_path())
	collisionObjects.erase(cache)
