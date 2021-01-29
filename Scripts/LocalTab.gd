extends Control

const APP_PATH = "user://";

export var repo_info_path : NodePath;
export var info_label_path : NodePath;
export var versions_option_button_path : NodePath;

onready var repo_info = get_node(repo_info_path);
onready var versions_option_button = get_node(versions_option_button_path);

var selected_repo_name;

func _ready():
	refresh();

func refresh():
	#OS.shell_open(str("file://", OS.get_user_data_dir()));
	
	set_info_text("", Color.black);
	versions_option_button.clear();
	
	for child in $VBoxContainer/ScrollContainer/VBoxContainer.get_children():
		child.queue_free();
	
	var dir = Directory.new();
	if !(dir.dir_exists(APP_PATH + "games")):
		print("Game directory not found. Creating one...");
		dir.open(APP_PATH);
		dir.make_dir(APP_PATH + "games");
	
	print("Game directory found. Opening...");
	var repos = list_files_in_directory(APP_PATH + "games");
	set_info_text("", Color.black);
	
	print(dir.get_current_dir())
	var button_group = ButtonGroup.new();
	for repo_data in repos:
		var folder_name = repo_data;
		var file = File.new();
		var data_path = APP_PATH + "games/" + folder_name;
		
		dir.open(OS.get_user_data_dir() + "/games/");
		var versions_amount = list_files_in_directory(OS.get_user_data_dir() + "/games/" + folder_name + "/versions").size();
		if versions_amount == 0:
			dir.remove(folder_name + "/versions");
			dir.remove(folder_name);
			set_info_text("Deleted entire project.", Color.black);
			repo_info.text = "No project selected.";
			return;
		
		#if !file.file_exists(data_path):
			#return;
		
		#file.open(data_path, file.READ);
		#var game_data = JSON.parse(file.get_as_text()).result;
		#file.close();
		
		var list_button = Button.new();
		list_button.toggle_mode = true;
		list_button.group = button_group;
		list_button.text = repo_data;
		list_button.clip_text = true;
		list_button.align = Button.ALIGN_LEFT;
		$VBoxContainer/ScrollContainer/VBoxContainer.add_child(list_button);
		
		list_button.connect("pressed", self, "_on_ListButton_pressed", [folder_name]);
		
	if button_group.get_buttons().size() != 0:
		button_group.get_buttons()[0].emit_signal("pressed");
		button_group.get_buttons()[0].pressed = true;
	
	set_info_text("Found " + str(repos.size()) + " local projects.", Color.black);

func _on_ListButton_pressed(folder_name):
	selected_repo_name = folder_name;
	
	var text = "";
	text += "Name: " + folder_name;
	text += "\nLocation: " + OS.get_user_data_dir() + "/games/" + folder_name;
	text += "\nVersions: ";
	
	var versions = list_files_in_directory(OS.get_user_data_dir() + "/games/" + folder_name + "/versions");
	for version in versions:
		if version != versions[0]:
			text += ", "
		text += version;
		versions_option_button.add_item(version);
	
	get_node(repo_info_path).text = text;

func list_files_in_directory(path):
	var files = [];
	var dir = Directory.new();
	dir.open(path);
	dir.list_dir_begin();
	
	while true:
		var file = dir.get_next();
		if file == "":
			break;
		elif not file.begins_with("."):
			files.append(file);
	
	dir.list_dir_end();
	return files;

func remove_files_in_directory(path):
	var dir = Directory.new();
	dir.open(path);
	dir.list_dir_begin();
	
	while true:
		var file = dir.get_next();
		if file == "":
			break;
		else:
			dir.remove(file);
			
	dir.list_dir_end();

func _on_TabContainer_tab_changed(tab):
	if tab == 0:
		get_node(info_label_path).show();
	else:
		get_node(info_label_path).hide();
	return;
	if tab == 0:
		get_node(info_label_path).show();
		refresh();


func _on_RefreshButton_pressed():
	refresh();

func set_info_text(text, color):
	var label_node = get_node(info_label_path);
	label_node.set("custom_colors/font_color", color)
	label_node.text = text;

func _on_DeleteButton_pressed():
	if (versions_option_button.text == ""):
		set_info_text("No version selected!", Color.red);
		return;
	
	var folder_path = OS.get_user_data_dir() + "/games/" + selected_repo_name + "/versions";
	var dir = Directory.new();
	dir.open(folder_path);
	remove_files_in_directory(folder_path + "/" + versions_option_button.text);
	dir.remove(versions_option_button.text);
	
	set_info_text("Deleted game folder: " + selected_repo_name + " v." + versions_option_button.text, Color.black)
	
	refresh();
