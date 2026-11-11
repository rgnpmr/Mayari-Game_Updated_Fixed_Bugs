class_name QuestItem extends Button
var quest : Quest

# Labels shown under the quest name. Change the wording here.
const TXT_COMPLETED : String = "Natapos"
const TXT_PROGRESS : String = "Progreso: "
const TXT_STEP : String = "Hakbang: "
# Bikol version (check the wording with a native speaker):
#   "Nahuman" / "Pag-abante: " / "Hakbang: "

@onready var title_label: Label = $TitleLabel
@onready var step_label: Label = $StepLabel

func initialize( q_data : Quest, q_state ) -> void:
	quest = q_data
	title_label.text = q_data.title

	if q_state.is_complete:
		step_label.text = TXT_COMPLETED
		step_label.modulate = Color.LIGHT_GREEN
		return

	var current_amount : int = q_state.amount if q_state.has("amount") else 0

	if q_data.target_amount > 0 and current_amount < q_data.target_amount:
		step_label.text = TXT_PROGRESS + str(current_amount) + "/" + str(q_data.target_amount)
	else:
		var step_count : int = q_data.steps.size()
		var completed_count : int = q_state.completed_steps.size()
		step_label.text = TXT_STEP + str(completed_count) + "/" + str(step_count)
	pass
