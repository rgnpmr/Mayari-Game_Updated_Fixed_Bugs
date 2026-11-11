@tool
@icon( "res://GUI/dialogue_system/icons/text_bubble.svg" )
class_name DialogueText extends DialogueItem

@export_multiline var text : String = "Placeholder text"
@export var voice: AudioStream
@export var show_gems : bool = false
