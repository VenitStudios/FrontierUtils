@tool
extends EditorPlugin

const GLOBAL_SCRIPTS: Dictionary[String, String] = {
	"NetworkTicker": "res://addons/netfrontier/core/network_ticker.gd",
	"NetworkSignals": "res://addons/netfrontier/core/network_signals.gd",
	"NetworkState": "res://addons/netfrontier/core/network_state.gd",
	"NetworkSerializer": "res://addons/netfrontier/core/network_serializer.gd"
}

func _enable_plugin() -> void:
	add_globals()


func _disable_plugin() -> void:
	remove_globals()


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	pass


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	pass


func add_globals() -> void:
	for key in GLOBAL_SCRIPTS.keys():
		var value : String = GLOBAL_SCRIPTS.get(key, "")
		add_autoload_singleton(key, value)


func remove_globals() -> void:
	for key in GLOBAL_SCRIPTS.keys():
		remove_autoload_singleton(key)
