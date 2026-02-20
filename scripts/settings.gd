extends Panel

@onready var aimsens = $AimSens
@onready var hipsens = $HipSens
@onready var aim_per = $AimSens/Percent
@onready var hip_per = $HipSens/Percent
@onready var data_handler = $"../../../../../Data Handler"
@onready var loading = $Loading
@onready var controls = $Controls

func _on_settings_pressed() -> void:
	show()
	loading.show()
	controls.delete_slots()
	
	var res = await GDSync.account_get_document("settings")
	var code = res["Code"]
	
	controls.create_slots()
	
	if code == ENUMS.ACCOUNT_GET_DOCUMENT_RESPONSE_CODE.SUCCESS:
		loading.hide()
		var settings = res["Result"]
		
		aimsens.value = (settings.get("aim_sens", 0) * 10000)
		hipsens.value = (settings.get("hip_sens", 0) * 10000)
	elif code == ENUMS.ACCOUNT_GET_DOCUMENT_RESPONSE_CODE.DOESNT_EXIST:
		aimsens.value = 10
		hipsens.value = 50
		loading.hide()
		
		var settings = {
			"aim_sens": (0.0001 * aimsens.value),
			"hip_sens": (0.0001 * hipsens.value)
		}
		data_handler.set_settings(settings)
	else:
		loading.hide()
		hide()

func _on_back_pressed() -> void:
	hide()

var applied_aim = false
var applied_controls = false
func _on_apply_pressed() -> void:
	applied_aim = false
	applied_controls = false
	var settings = {
		"aim_sens": (0.0001 * aimsens.value),
		"hip_sens": (0.0001 * hipsens.value)
	}
	$Apply.text = "Applying..."
	$Apply.disabled = true
	$Back.disabled = true
	controls.save_controls()
	data_handler.set_settings(settings)
	while not applied_aim and not applied_controls:
		await get_tree().create_timer(0.01).timeout
	$Apply.text = "Applied!"
	$Apply.disabled = false
	$Back.disabled = false
	await get_tree().create_timer(2,false,false,true).timeout
	$Apply.text = "Apply Settings"

func _on_sens_value_changed(og_value: float) -> void:
	var value = round(og_value)
	
	$AimSens/Percent.text = "%" + str(value).replace(".0", "")

func _on_hip_sens_value_changed(og_value: float) -> void:
	var value = round(og_value)
	
	$HipSens/Percent.text = "%" + str(value).replace(".0", "")
