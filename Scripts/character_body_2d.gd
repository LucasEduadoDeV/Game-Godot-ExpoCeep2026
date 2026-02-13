extends CharacterBody2D

@onready var CollsionFloor: CollisionShape2D = $CollisionShape2D
@onready var anim: AnimatedSprite2D = $Visual/AnimatedSprite2D
@export var sprite_default_faces_right: bool = false
@onready var HurtBoxStand: CollisionShape2D = $HurtBoxStand/Area2D/HurtBoxStandShape
@onready var Flecha: CollisionShape2D = $Node2D/Area2D/Flecha
@onready var HitBox: CollisionShape2D = $Hitbox/Hitbox/HitBoxShape2D
@onready var anima: AnimationPlayer = $AnimationPlayer

@onready var HitBoxNode2D: Node2D = $"Hitbox"
@onready var HurtBoxStandNode2D: Node2D = $HurtBoxStand
@onready var FlechaNode2D: Node2D = $Node2D






enum STATES { IDLE, WALK, JUMP, LANDING, CROUCH, UNCROUCH, BACKSTEP, DASH, ATTACK, ATTACK2, STANDGUARD, OFFSTANDGUARD, CROUCHGUARD, OFFCROUCHGUARD, ATTACK3, STATICCROUCH, ATTACK4, ATTACK5, EVADE, OFFEVADE, EVADELEFT}
var state: int = STATES.IDLE
var facing_dir: int = 1

var double_tap_window: float = 0.25
var time_double_tap_dash: float = 0.0
var start_double_tap_dash: bool = false
var time_double_tap_backstep: float = 0.0
var start_double_tap_backstep: bool = false

var dash_time: float = 0.42
var dash_timer: float = 0.0
var is_dashing: bool = false

var backstep_time: float = 0.32
var backstep_timer: float = 0.0
var is_backstepping: bool = false

var evade_time: float = 0.20
var evade_timer: float = 0.0

const SPEED: float = 100.0
const JUMP_VELOCITY: float = -630.0
const DASH_SPEED: float = 340.0
const DASH_ATTACK_SPEED: float = 260.0
const EVADE_SPEED: float = 400.0
const BACK_SPEED: float = 250.0
const HURTBOX_BASE_FACING := -1
# -1 = esquerda
#  1 = direita

var gravity: float = float(ProjectSettings.get_setting("physics/2d/default_gravity"))

var gravity_up := gravity * 2.0
var gravity_down := gravity * 3.5

func _ready() -> void:
	_update_sprite_flip()
	HurtBoxStand.visible = false
	HurtBoxStand.disabled = false
	CollsionFloor.visible = false
	Flecha.visible = false
	FlechaNode2D.scale.x = -1

func _physics_process(delta: float) -> void:
	double_timer(delta)
	dash_enable()
	update_collision_direction()
	update_hitbox_direction()
	update_hurtbox_facing()
	flecha_direction()
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
		
		if Input.is_action_just_pressed("punch"):
			is_dashing = false
			velocity.x = DASH_ATTACK_SPEED
			change_state(STATES.ATTACK4)
			return
			
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
			STATES.ATTACK3: $CombatController.start_attack3()
			STATES.ATTACK4: $CombatController.start_attack4()
			STATES.ATTACK5: $CombatController.start_attack5()
			STATES.STANDGUARD: pass
			STATES.OFFSTANDGUARD: pass
			STATES.CROUCHGUARD: pass
			STATES.OFFCROUCHGUARD: pass
			STATES.STATICCROUCH: state_static_crocuh()
			STATES.EVADE: state_evade()
			STATES.EVADELEFT: state_evadeLeft()
	move_and_slide()
	
func change_state(new_state: int) -> void:
	if state == new_state: return
	state = new_state
	if new_state == STATES.LANDING:
		HurtBoxStand.disabled = false
		HurtBoxStandNode2D.visible = true
	if new_state == STATES.JUMP:
		velocity.y = JUMP_VELOCITY
		anima.play("hurtbox_jump")
		HurtBoxStand.disabled = true
	if new_state == STATES.CROUCH: anima.play("crouch")
	if new_state == STATES.DASH: anima.play("dash")
	if new_state == STATES.BACKSTEP: 
		anima.play("hurtbox_backstep")
		HurtBoxStandNode2D.visible = true
		HurtBoxStand.disabled = true
	if new_state == STATES.JUMP: 
		HurtBoxStandNode2D.visible = true
		HurtBoxStand.disabled = true
	if new_state == STATES.IDLE:
		HurtBoxStandNode2D.visible = true
		HurtBoxStand.disabled = false
	if new_state == STATES.ATTACK:
		velocity.x = 0
	if new_state == STATES.ATTACK2:
		velocity.x = 0
	if new_state == STATES.EVADE:
		anima.play("evade_right")
		velocity.x = EVADE_SPEED
	if new_state == STATES.EVADELEFT:
		anima.play("evade_left")
		velocity.x = -EVADE_SPEED
	if new_state == STATES.OFFEVADE:
		anima.play("offEvade")

func state_idle() -> void:
	if $CombatController.attacking:
		return
	
	anima.play("idle"); velocity.x = 0
	if Input.is_action_pressed("right") or Input.is_action_pressed("left"): change_state(STATES.WALK); return
	if Input.is_action_just_pressed("jump") and is_on_floor(): change_state(STATES.JUMP); return
	if Input.is_action_just_pressed("crouch") and is_on_floor(): change_state(STATES.CROUCH); return
	if Input.is_action_just_pressed("punch") and is_on_floor(): change_state(STATES.ATTACK); return
	if Input.is_action_just_pressed("kick") and is_on_floor(): change_state(STATES.ATTACK2); return
	if Input.is_action_pressed("crouch") and is_on_floor(): change_state(STATES.CROUCH); return
	if Input.is_action_just_pressed("evade") and is_on_floor() and facing_dir == 1: change_state(STATES.EVADE); return
	if Input.is_action_just_pressed("evade") and is_on_floor() and facing_dir == -1: change_state(STATES.EVADELEFT); return
	
func state_walk() -> void:	
	if is_dashing: return
	anima.play("walk")
	if Input.is_action_pressed("right"):
		velocity.x = SPEED; _set_facing(1)
	elif Input.is_action_pressed("left"):
		velocity.x = -SPEED; _set_facing(1)
	else:
		velocity.x = 0; change_state(STATES.IDLE); return
	if Input.is_action_just_pressed("jump") and is_on_floor(): change_state(STATES.JUMP)
	if Input.is_action_just_pressed("punch") and is_on_floor(): change_state(STATES.ATTACK)
	if Input.is_action_just_pressed("kick") and is_on_floor(): change_state(STATES.ATTACK2)
	if Input.is_action_just_pressed("crouch") and is_on_floor(): change_state(STATES.CROUCH)
	if Input.is_action_just_pressed("evade") and is_on_floor() and facing_dir == 1: change_state(STATES.EVADE); return
	if Input.is_action_just_pressed("evade") and is_on_floor() and facing_dir == -1: change_state(STATES.EVADELEFT); return
	

func state_jump() -> void:
	if is_on_floor(): change_state(STATES.LANDING)

func state_landing(_delta: float) -> void:
	velocity.x = 0; anima.play("landing")
	#landing_timer -= delta
	#if landing_timer <= 0.0: change_state(STATES.IDLE)

func state_crouch() -> void:
	velocity.x = 0
	if Input.is_action_just_released("crouch"): change_state(STATES.UNCROUCH)
	if Input.is_action_just_pressed("kick"): change_state(STATES.ATTACK3)
	if Input.is_action_just_pressed("punch"): change_state(STATES.ATTACK5)

func state_uncrouch() -> void:
	velocity.x = 0; anima.play("uncrouch")

func state_dash() -> void:
	if not is_dashing: change_state(STATES.IDLE)
	if Input.is_action_just_pressed("punch"): change_state(STATES.ATTACK4)
			
func state_backstep() -> void:
	if not is_backstepping: change_state(STATES.IDLE)
	
func state_attack() -> void:
	pass
	
func state_standGuard() -> void:
	pass
	
func state_crouchGuard() -> void:
	pass
	
func state_off_standGuard() -> void:
	pass
	
func state_off_crouchGuard() -> void:
	pass
	
func state_evade() -> void:
	pass
	
func state_evadeLeft() -> void:
	pass
	
func state_offEvade() -> void:
	pass
	
func state_static_crocuh() -> void:
	anim.play("staticCrouch")
	if not Input.is_action_pressed("crouch"):
		# Se não estiver, ele nem para no agachado, já pula pro levantar
		change_state(STATES.UNCROUCH)
	else:
		anim.play("staticCrouch")
	if Input.is_action_just_pressed("kick"): change_state(STATES.ATTACK3)
	if Input.is_action_just_pressed("punch"): change_state(STATES.ATTACK5)
	
func start_backstep() -> void:
	anim.play("BackStep")
	if is_dashing or is_backstepping: return
	is_backstepping = true
	backstep_timer = backstep_time
	change_state(STATES.BACKSTEP)

func start_dash() -> void:
	if is_dashing: return
	is_dashing = true; dash_timer = dash_time; change_state(STATES.DASH)
	velocity.x = DASH_SPEED * facing_dir

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "uncrouch": 
		change_state(STATES.IDLE)
		
	elif anim_name == "landing":
		change_state(STATES.IDLE)
		
	elif anim_name == "evade_right":
		change_state(STATES.IDLE)
		FlechaNode2D.scale.x = 1
		
	elif anim_name == "offEvade":
		change_state(STATES.IDLE)
		
	elif anim_name == "evade_left":
		change_state(STATES.IDLE)
		FlechaNode2D.scale.x = -1
		
		
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
			
func evadetimer(delta: float) -> void:
	if Input.is_action_just_pressed("evade"):
		evadetimer(delta)

# DIREÇÃO EM QUE O "PERSONAGEM" ESTA OLHANDO
func get_facing_dir() -> int:
	return facing_dir

func _set_facing(dir: int) -> void:
	if dir == facing_dir: return
	facing_dir = dir
	_update_sprite_flip()
	update_hurtbox_facing()

func _update_sprite_flip() -> void:
	if sprite_default_faces_right:
		anim.flip_h = (facing_dir == -1)
	else:
		anim.flip_h = (facing_dir == 1)
		
func flecha_direction() -> void:
	if FlechaNode2D.scale.x == -1:
		facing_dir = 1
	else:
		facing_dir = -1
		
func update_hurtbox_facing():
	pass
		
func update_collision_direction():
	match state:
		pass
	
	#AUTOMATIZA O "FLIP_H" DA HURTBOXSTAND
func face_vec(v: Vector2) -> Vector2:
	return Vector2(v.x * facing_dir, v.y)

func update_hitbox_direction():
	match state:
		STATES.ATTACK, STATES.JUMP, STATES.BACKSTEP, STATES.ATTACK2, STATES.ATTACK3, STATES.ATTACK4, STATES.IDLE, STATES.CROUCH, STATES.WALK:
			HurtBoxStandNode2D.scale.x = -facing_dir
			HitBoxNode2D.scale.x = -facing_dir
		STATES.CROUCHGUARD:
			HurtBoxStandNode2D.scale.x = -facing_dir
func change_visible_hitboxes_hurtboxes():
	pass
