extends CharacterBody2D

@onready var CollsionFloor: CollisionShape2D = $CollisionShape2D
@onready var anim: AnimatedSprite2D = $Visual/AnimatedSprite2D
@export var sprite_default_faces_right: bool = false
@onready var HurtBoxStand: CollisionShape2D = $HurtBoxStand/Area2D/HurtBoxStandShape
@onready var HitBox: CollisionShape2D = $Hitbox/Hitbox/HitBoxShape2D
@onready var anima: AnimationPlayer = $AnimationPlayer

@onready var HitBoxNode2D: Node2D = $"Hitbox"
@onready var HurtBoxStandNode2D: Node2D = $HurtBoxStand




enum STATES { IDLE, WALK, JUMP, LANDING, CROUCH, UNCROUCH, BACKSTEP, DASH, ATTACK, ATTACK2}
var state: int = STATES.IDLE
var facing_dir: int = 1

var landing_duration: float = 0.15
var landing_timer: float = 0.0
var double_tap_window: float = 0.25
var time_double_tap_dash: float = 0.0
var start_double_tap_dash: bool = false
var time_double_tap_backstep: float = 0.0
var start_double_tap_backstep: bool = false

var dash_time: float = 0.32
var dash_timer: float = 0.0
var is_dashing: bool = false

var backstep_time: float = 0.32
var backstep_timer: float = 0.0
var is_backstepping: bool = false

const SPEED: float = 100.0
const JUMP_VELOCITY: float = -630.0
const DASH_SPEED: float = 350.0
const BACK_SPEED: float = 250.0

var gravity: float = float(ProjectSettings.get_setting("physics/2d/default_gravity"))

var gravity_up := gravity * 2.0
var gravity_down := gravity * 3.5

func _ready() -> void:
	if anim and not anim.is_connected("animation_finished", Callable(self, "_on_animated_sprite_2d_animation_finished")):
		anim.connect("animation_finished", Callable(self, "_on_animated_sprite_2d_animation_finished"))
	_update_sprite_flip()
	HurtBoxStand.visible = true
	HurtBoxStand.disabled = false
	CollsionFloor.visible = false
	
func _physics_process(delta: float) -> void:
	double_timer(delta)
	dash_enable()
	update_collision_direction()
	update_hitbox_direction()
	print(facing_dir)
	if velocity.y < 0:
	# SUBINDO
		velocity.y += gravity_up * delta
	else:
	# CAINDO
		velocity.y += gravity_down * delta
		
	if is_dashing:
		velocity.x = DASH_SPEED * facing_dir
		dash_timer -= delta
		if dash_timer <= 0.0:
			is_dashing = false
			change_state(STATES.IDLE)
			
	elif is_backstepping:
		velocity.x = -BACK_SPEED * facing_dir
		backstep_timer -= delta
		if backstep_timer <= 0.0:
			is_backstepping = false
			change_state(STATES.IDLE)
			
	else:
		match state:
			STATES.IDLE: state_idle()
			STATES.WALK: state_walk()
			STATES.JUMP:  state_jump()
			STATES.LANDING: state_landing(delta)
			STATES.CROUCH: state_crouch()
			STATES.UNCROUCH: state_uncrouch()
			STATES.DASH: state_dash()
			STATES.BACKSTEP: state_backstep()
			STATES.ATTACK: $CombatController.start_attack()
			STATES.ATTACK2: $CombatController.start_attack2()
	move_and_slide()
	
func change_state(new_state: int) -> void:
	if state == new_state: return
	state = new_state
	if new_state == STATES.LANDING: 
		landing_timer = landing_duration
		HurtBoxStand.disabled = false
		HurtBoxStandNode2D.visible = true
	if new_state == STATES.JUMP:
		velocity.y = JUMP_VELOCITY
		anima.play("hurtbox_jump")
		HurtBoxStand.disabled = true
	if new_state == STATES.CROUCH: anim.play("crouch") 
	if new_state == STATES.BACKSTEP: 
		anima.play("hurtbox_backstep")
		HurtBoxStandNode2D.visible = true
		HurtBoxStand.disabled = true
	if new_state == STATES.JUMP: 
		HurtBoxStandNode2D.visible = true
		HurtBoxStand.disabled = true
	if new_state == STATES.IDLE:
		HurtBoxStand.position = face_vec(Vector2(8.0, 87.0))
		HurtBoxStand.scale = Vector2(1.0, 1.0)
		HurtBoxStandNode2D.visible = true
		HurtBoxStand.disabled = false
	if new_state == STATES.ATTACK:
		velocity.x = 0
	if new_state == STATES.ATTACK2:
		velocity.x = 0

func state_idle() -> void:
	if $CombatController.attacking:
		return
	
	anim.play("idle"); velocity.x = 0
	if Input.is_action_pressed("right") or Input.is_action_pressed("left"): change_state(STATES.WALK); return
	if Input.is_action_just_pressed("jump") and is_on_floor(): change_state(STATES.JUMP); return
	if Input.is_action_just_pressed("crouch") and is_on_floor(): change_state(STATES.CROUCH); return
	if Input.is_action_just_pressed("punch") and is_on_floor(): change_state(STATES.ATTACK)
	if Input.is_action_just_pressed("kick") and is_on_floor(): change_state(STATES.ATTACK2)

func state_walk() -> void:	
	if is_dashing: return
	anim.play("walk")
	if Input.is_action_pressed("right"):
		velocity.x = SPEED; _set_facing(1)
	elif Input.is_action_pressed("left"):
		velocity.x = -SPEED; _set_facing(1)
	else:
		velocity.x = 0; change_state(STATES.IDLE); return
	if Input.is_action_just_pressed("jump") and is_on_floor(): change_state(STATES.JUMP)
	if Input.is_action_just_pressed("punch") and is_on_floor(): change_state(STATES.ATTACK)
	if Input.is_action_just_pressed("kick") and is_on_floor(): change_state(STATES.ATTACK2)

func state_jump() -> void:
	if is_on_floor(): change_state(STATES.LANDING)

func state_landing(delta: float) -> void:
	velocity.x = 0; anim.play("landing")
	landing_timer -= delta
	if landing_timer <= 0.0: change_state(STATES.IDLE)

func state_crouch() -> void:
	velocity.x = 0
	if Input.is_action_just_released("crouch"): change_state(STATES.UNCROUCH)

func state_uncrouch() -> void:
	velocity.x = 0; anim.play("uncrouch")

func state_dash() -> void:
	anim.play("dash")
	if not is_dashing: change_state(STATES.IDLE)
	
func state_backstep() -> void:
	if not is_backstepping: change_state(STATES.IDLE)
	
func state_attack() -> void:
	pass
	
func start_backstep() -> void:
	anim.play("BackStep")
	if is_dashing or is_backstepping: return
	is_backstepping = true
	backstep_timer = backstep_time
	change_state(STATES.BACKSTEP)

func start_dash() -> void:
	anim.play("dash")
	if is_dashing: return
	is_dashing = true; dash_timer = dash_time; change_state(STATES.DASH)
	velocity.x = DASH_SPEED * facing_dir

func _on_animated_sprite_2d_animation_finished() -> void:
	if anim.animation == "uncrouch": change_state(STATES.IDLE)

func dash_enable() -> void:
	if Input.is_action_just_released("dash") and is_on_floor() and state == STATES.WALK:
		if start_double_tap_dash and time_double_tap_dash <= double_tap_window:
			start_double_tap_dash = false; start_dash()
		else:
			start_double_tap_dash = true; time_double_tap_dash = 0.0
			
	if Input.is_action_just_released("BackStep") and is_on_floor() and state == STATES.WALK:
		if start_double_tap_backstep and time_double_tap_backstep <= double_tap_window:
			start_double_tap_backstep = false; start_backstep()
		else:
			start_double_tap_backstep = true; time_double_tap_backstep = 0.0

func double_timer(delta: float) -> void:
	if start_double_tap_dash:
		time_double_tap_dash += delta
		if time_double_tap_dash >= double_tap_window:
			start_double_tap_dash = false; time_double_tap_dash = 0.0
	if start_double_tap_backstep:
		time_double_tap_backstep += delta
		if time_double_tap_backstep >= double_tap_window:
			start_double_tap_backstep = false; time_double_tap_backstep = 0.0

# DIREÇÃO EM QUE O "PERSONAGEM" ESTA OLHANDO
func get_facing_dir() -> int:
	return facing_dir

func _set_facing(dir: int) -> void:
	if dir == facing_dir: return
	facing_dir = dir
	_update_sprite_flip()

func _update_sprite_flip() -> void:
	if sprite_default_faces_right:
		anim.flip_h = (facing_dir == -1)
	else:
		anim.flip_h = (facing_dir == 1)
		
func update_collision_direction():
	match state:
		STATES.IDLE:
			HurtBoxStand.position = face_vec(Vector2(8.0, 87.0))
			HurtBoxStand.scale = Vector2(1.0, 1.0)
		STATES.WALK:
			HurtBoxStand.position = face_vec(Vector2(8.0, 87.0))
			HurtBoxStand.scale = Vector2(1.0, 1.0)
		STATES.CROUCH:
			HurtBoxStand.position = face_vec(Vector2(3.0, 95.02))
			HurtBoxStand.scale = Vector2(1.0, 0.76)
		_:
			pass  # outros estados podem ser tratados aqui
	
	#AUTOMATIZA O "FLIP_H" DA HURTBOXSTAND
func face_vec(v: Vector2) -> Vector2:
	return Vector2(v.x * facing_dir, v.y)

func update_hitbox_direction():
	match state:
		STATES.ATTACK:
			HitBoxNode2D.scale = face_vec(Vector2(-1.0, 1.0))
		STATES.JUMP:
			HurtBoxStandNode2D.scale = face_vec(Vector2(-1.0, 1.0))
		STATES.BACKSTEP:
			HurtBoxStandNode2D.scale = face_vec(Vector2(-1.0, 1.0))
		STATES.ATTACK2:
			HitBoxNode2D.scale = face_vec(Vector2(-1.0, 1.0))
			HurtBoxStandNode2D.scale = face_vec(Vector2(-1.0, 1.0))
		
func change_visible_hitboxes_hurtboxes():
	pass
