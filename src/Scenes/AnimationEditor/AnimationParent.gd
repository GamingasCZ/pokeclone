extends PopupDialog
signal animation_added
signal animation_cancelled
signal animation_edited
signal animation_deleted

func loadFromDict(popupToModify : PopupDialog, dict : Dictionary):
	for key in dict.controls.keys():
		var val = dict.controls[key]

		var setting = popupToModify.get_node_or_null("%"+key)
		if setting == null: push_error("Setting not valid for this type! (%s, %s)" % [key, val])
		
		if setting is SpinBox: setting.value = val
		elif setting is CheckBox: setting.pressed = val
		elif setting is ColorPickerButton: setting.color = Color(val)
		elif setting is MenuButton: setting.get_popup().set_current_index(val)
		
			
func createSettingDict(name) -> Dictionary:
	# Make sure only one popup is on the screen!
	var settingDict = {}
	settingDict.id = len(Game.AnimationTimeline)
	settingDict.name = name
	settingDict.type = name
	settingDict.controls = {}
	for control in get_tree().get_nodes_in_group("modifiables"):
		if control is SpinBox: settingDict.controls[control.name] = control.value
		elif control is CheckBox: settingDict.controls[control.name] = control.pressed
		elif control is ColorPickerButton: settingDict.controls[control.name] = control.color
		elif control is MenuButton: settingDict.controls[control.name] = 0
	
	return settingDict

func createPopup(popup : String, editing : bool = false, index : int = 0) -> PopupDialog:
	var popupInstance = load("res://Scenes/AnimationEditor/%s.tscn" % [popup]).instance()
	popupInstance.popup_exclusive = true
	get_parent().add_child(popupInstance)
	
	var settings : Dictionary
	if editing:
		settings = Game.AnimationTimeline[index]
		loadFromDict(popupInstance, Game.AnimationTimeline[index])
		popupInstance.get_node("VBoxContainer/Confirm").connect("pressed", self, "confirmEditAnimation", [popupInstance, settings["id"]])
		popupInstance.get_node("VBoxContainer/Delete").connect("pressed", self, "deleteAnimation", [popupInstance, settings["id"]])
		
	else:
		settings = createSettingDict(popupInstance.get_node("VBoxContainer/Title").text)
		popupInstance.get_node("VBoxContainer/Delete").text = "Cancel"
		popupInstance.get_node("VBoxContainer/Delete").connect("pressed", self, "cancelAddAnimation", [popupInstance, settings["id"]])
		
		Game.AnimationTimeline.append(settings)
		popupInstance.get_node("VBoxContainer/Confirm").connect("pressed", self, "confirmAddAnimation", [popupInstance, settings["id"]])
	
	# Give signals to all popup controls, change values in their settings dict
	for control in get_tree().get_nodes_in_group("modifiables"):
		if control is SpinBox: control.connect("value_changed", self, "modifyPopupVal", [control.name, settings["id"]])
		elif control is CheckBox: control.connect("toggled", self, "modifyPopupVal", [control.name, settings["id"]])
		elif control is ColorPickerButton: control.connect("color_changed", self, "modifyPopupVal", [control.name, settings["id"]])
		elif control is MenuButton: control.get_popup().connect("id_pressed", self, "modifyPopupVal", [control.name, settings["id"]])
		
	popupInstance.popup()
	return popupInstance

func modifyPopupVal(newValue, editKey : String, index : int):
	Game.AnimationTimeline[index].controls[editKey] = newValue

func confirmAddAnimation(popup : PopupDialog, modIndex : int):
	popup.queue_free()
	popup.emit_signal("animation_added", modIndex)
	
func confirmEditAnimation(popup : PopupDialog, modIndex : int):
	popup.queue_free()
	popup.emit_signal("animation_edited", modIndex)
	
func deleteAnimation(popup : PopupDialog, modIndex : int):
	for settings in Game.AnimationTimeline.slice(modIndex, -1):
		settings["id"] -= 1
	Game.AnimationTimeline.pop_at(modIndex)
		
	popup.queue_free()
	popup.emit_signal("animation_deleted", modIndex)	
	
func cancelAddAnimation(popup : PopupDialog, modIndex : int):
	Game.AnimationTimeline.pop_at(modIndex)
	popup.queue_free()
	popup.emit_signal("animation_cancelled")
