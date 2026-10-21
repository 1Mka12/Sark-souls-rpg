
extends Node3D

var player: CharacterBody3D
var camera: Camera3D
var status_label: Label
var move_state: Dictionary = {
    "forward": false,
    "back": false,
    "left": false,
    "right": false
}

const SPEED: float = 4.0
const GRAVITY: float = 18.0

func _ready() -> void:
    create_world()
    create_player()
    create_ui()

func create_world() -> void:
    var world_env := WorldEnvironment.new()
    var env := Environment.new()
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.035, 0.035, 0.055)
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.45, 0.45, 0.55)
    env.ambient_light_energy = 0.7
    world_env.environment = env
    add_child(world_env)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-50, -30, 0)
    sun.light_energy = 1.2
    add_child(sun)

    var ground := StaticBody3D.new()
    ground.name = "RuinsGround"
    add_child(ground)

    var ground_mesh := MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(80, 1, 80)
    ground_mesh.mesh = box
    ground_mesh.position.y = -0.5

    var stone := StandardMaterial3D.new()
    stone.albedo_color = Color(0.19, 0.19, 0.22)
    ground_mesh.material_override = stone
    ground.add_child(ground_mesh)

    var ground_collision := CollisionShape3D.new()
    var ground_shape := BoxShape3D.new()
    ground_shape.size = Vector3(80, 1, 80)
    ground_collision.shape = ground_shape
    ground_collision.position.y = -0.5
    ground.add_child(ground_collision)

    # Простий декоративний блок — уламок руїн.
    var ruin := MeshInstance3D.new()
    var ruin_mesh := BoxMesh.new()
    ruin_mesh.size = Vector3(2, 3, 2)
    ruin.mesh = ruin_mesh
    ruin.position = Vector3(4, 1.5, -5)

    var ruin_mat := StandardMaterial3D.new()
    ruin_mat.albedo_color = Color(0.27, 0.25, 0.24)
    ruin.material_override = ruin_mat
    add_child(ruin)

func create_player() -> void:
    player = CharacterBody3D.new()
    player.name = "Player"
    add_child(player)

    var collision := CollisionShape3D.new()
    var capsule := CapsuleShape3D.new()
    capsule.radius = 0.4
    capsule.height = 1.8
    collision.shape = capsule
    collision.position.y = 0.9
    player.add_child(collision)

    var body := MeshInstance3D.new()
    var body_mesh := CapsuleMesh.new()
    body_mesh.radius = 0.4
    body_mesh.height = 1.8
    body.mesh = body_mesh
    body.position.y = 0.9

    var armor := StandardMaterial3D.new()
    armor.albedo_color = Color(0.16, 0.19, 0.25)
    body.material_override = armor
    player.add_child(body)

    camera = Camera3D.new()
    camera.position = Vector3(0, 4, 7)
    camera.rotation_degrees = Vector3(-20, 0, 0)
    camera.current = true
    player.add_child(camera)

func create_ui() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)

    status_label = Label.new()
    status_label.text = "DARK LANDS RPG  |  HP: 100"
    status_label.position = Vector2(18, 14)
    status_label.add_theme_font_size_override("font_size", 20)
    layer.add_child(status_label)

    add_control_button(layer, "↑", Vector2(100, -150), "forward")
    add_control_button(layer, "↓", Vector2(100, -70), "back")
    add_control_button(layer, "←", Vector2(20, -70), "left")
    add_control_button(layer, "→", Vector2(180, -70), "right")
    add_control_button(layer, "УДАР", Vector2(-150, -100), "attack")

func add_control_button(
    layer: CanvasLayer,
    caption: String,
    offset: Vector2,
    action: String
) -> void:
    var button := Button.new()
    button.text = caption
    button.custom_minimum_size = Vector2(68, 60)
    button.anchor_left = 0.0 if offset.x >= 0 and action != "attack" else 1.0
    button.anchor_right = button.anchor_left
    button.anchor_top = 1.0
    button.anchor_bottom = 1.0
    button.offset_left = offset.x
    button.offset_right = offset.x + 68
    button.offset_top = offset.y
    button.offset_bottom = offset.y + 60
    button.add_theme_font_size_override("font_size", 20)
    layer.add_child(button)

    if action == "attack":
        button.pressed.connect(_attack)
    else:
        button.button_down.connect(_set_move.bind(action, true))
        button.button_up.connect(_set_move.bind(action, false))

func _set_move(action: String, pressed: bool) -> void:
    move_state[action] = pressed

func _physics_process(delta: float) -> void:
    if not is_instance_valid(player):
        return

    var direction := Vector3.ZERO

    if move_state["forward"] or Input.is_key_pressed(KEY_W):
        direction.z -= 1.0
    if move_state["back"] or Input.is_key_pressed(KEY_S):
        direction.z += 1.0
    if move_state["left"] or Input.is_key_pressed(KEY_A):
        direction.x -= 1.0
    if move_state["right"] or Input.is_key_pressed(KEY_D):
        direction.x += 1.0

    direction = direction.normalized()
    player.velocity.x = direction.x * SPEED
    player.velocity.z = direction.z * SPEED

    if not player.is_on_floor():
        player.velocity.y -= GRAVITY * delta
    else:
        player.velocity.y = 0.0

    player.move_and_slide()

func _attack() -> void:
    status_label.text = "DARK LANDS RPG  |  АТАКА!"
