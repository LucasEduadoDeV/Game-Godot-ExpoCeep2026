extends Node

@onready var character: CharacterBody2D = get_parent()
@onready var anima: AnimationPlayer = $"../AnimationPlayer"
@onready var HitBox: CollisionShape2D = $"../Hitbox/Hitbox/HitBoxShape2D"
@onready var HurtBoxStand: CollisionShape2D = $"../HurtBoxStand/Area2D/HurtBoxStandShape"
@onready var ScriptMove: CharacterBody2D = $".."

@onready var HitBoxNode2D: Node2D = $"../Hitbox"
@onready var HurtBoxStandNode2D: Node2D = $"../HurtBoxStand"



enum ATTACK {LightAttackStand, StrongAttackStand}

var attacking := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if not anima.is_connected("animation_finished", Callable(self, "_on_animation_finished")):
		anima.connect("animation_finished", Callable(self, "_on_animation_finished"))
	HitBox.disabled = true
	HurtBoxStand.disabled = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	change_visible_hitboxes_hurtboxes()

func start_attack():
	if attacking:
		return
		
	attacking = true
	update_hurtbox_state()
	anima.play("SoftPunchStand_LightAttack")
	
func start_attack2():
	if attacking:
		return
		
	attacking = true
	update_hurtbox_state()
	anima.play("SoftKickStand_HardAttack")
	
func start_attack3():
	if attacking:
		return
		
	attacking = true
	update_hurtbox_state()
	anima.play("SoftKickCrouch_HardAttack")
	
func start_attack4():
	if attacking:
		return
		
	attacking = true
	update_hurtbox_state()
	anima.play("SoftPunchDash_LightAttack")
	
func start_attack5():
	if attacking:
		return
		
	attacking = true
	update_hurtbox_state()
	anima.play("SoftPunchCrouch_LightAttack")

func update_hurtbox_state():
	if attacking == false:
		HurtBoxStand.disabled = false
	else:
		HurtBoxStand.disabled = true

func _on_animation_finished(anim_name: StringName) -> void:
	if anim_name == "SoftPunchStand_LightAttack":
		attacking = false
		update_hurtbox_state()
		character.change_state(character.STATES.IDLE)
		
	elif anim_name == "SoftKickStand_HardAttack":
		attacking = false
		update_hurtbox_state()
		character.change_state(character.STATES.IDLE)
		
	elif anim_name == "SoftKickCrouch_HardAttack":
		attacking = false
		update_hurtbox_state()
		character.change_state(character.STATES.STATICCROUCH)
		
	elif anim_name == "SoftPunchDash_LightAttack":
		attacking = false
		update_hurtbox_state()
		character.change_state(character.STATES.IDLE)
		
	elif anim_name == "SoftPunchCrouch_LightAttack":
		attacking = false
		update_hurtbox_state()
		character.change_state(character.STATES.STATICCROUCH)
	
func change_visible_hitboxes_hurtboxes():
	if attacking == true:
		HitBox.visible = true
		HurtBoxStand.visible = true
	else:
		HitBox.visible = false
