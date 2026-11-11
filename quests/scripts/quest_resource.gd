class_name Quest extends Resource

@export var title : String
@export_multiline var description : String
@export var steps : Array[ String ]
@export var step_targets : Array[ int ] = []
@export var auto_complete_on_all_steps : bool = true
@export var reward_xp : int
@export var reward_items : Array[ QuestRewardItem ] = []
@export var target_amount : int = 0
@export var icon : Texture2D
