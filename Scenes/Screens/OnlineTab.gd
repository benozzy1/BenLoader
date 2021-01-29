extends Control

var APP_PATH = OS.get_user_data_dir();

export var repo_info_path : NodePath;
export var info_label_path : NodePath;
export var downloading_panel_path : NodePath;
export var versions_option_button_path : NodePath;

onready var repo_info = get_node(repo_info_path);
onready var info_label = get_node(info_label_path);
onready var downloading_panel = get_node(downloading_panel_path);
onready var versions_option_button = get_node(versions_option_button_path);

var repo_data_dict = {}

var auth = "52622b7669e073c0c781f82eb7b18e0a6c747f19";
var headers = ["Authorization: token " + auth]

var download_request;
var downloading = false;

func _ready():
	download_request = HTTPRequest.new();
	add_child(download_request);
	download_request.use_threads = true;
	download_request.connect("request_completed", self, "_on_Download_completed");

var download_percent = 0;
func _process(delta):
	if downloading:
		download_percent = (float(download_request.get_downloaded_bytes()) / float(download_request.get_body_size())) * 100;
		print(round(download_percent));
		set_info_text("Downloading file... (" + str(round(download_percent)) + "% Complete)", Color.black);

func refresh():
	print("Online refreshed");
	downloading_panel.show();
	
	repo_data_dict.clear();
	
	set_info_text("", Color.black);
	repo_info.text = "Loading...";
	
	for child in $VBoxContainer/ScrollContainer/VBoxContainer.get_children():
		child.queue_free();
	set_info_text("Refreshing...", Color.black);
	
	var repos_request = HTTPRequest.new();
	add_child(repos_request);
	repos_request.connect("request_completed", self, "_on_RepoData_request_completed", [repos_request]);
	repos_request.request("https://api.github.com/users/benozzy1/repos", headers, true, HTTPClient.METHOD_GET);

func _on_RepoData_request_completed(result, response_code, headers, body, request_from):
	request_from.queue_free();
	
	var json = JSON.parse(body.get_string_from_utf8());
	if json.result is Dictionary:
		if json.result.message:
			set_info_text("Github API rate limit exceeded. Wait at least an hour.", Color.red);
			downloading_panel.hide();
			return;
	
	var is_last = false;
	for repo_data in json.result:
		if repo_data == json.result[json.result.size() - 1]:
			is_last = true;
		
		repo_data_dict[repo_data] = [];

		var versions_request = HTTPRequest.new();
		add_child(versions_request);
		versions_request.connect("request_completed", self, "_on_VersionData_request_completed", [repo_data, versions_request, is_last]);
		versions_request.request("https://api.github.com/repos/benozzy1/" + repo_data.name + "/releases", headers, true, HTTPClient.METHOD_GET);

func _on_VersionData_request_completed(result, response_code, headers, body, repo_data, request_from, is_last):
	request_from.queue_free();
	
	var json = JSON.parse(body.get_string_from_utf8());
	if json.result is Dictionary:
		if json.result.message:
			set_info_text("Github API rate limit exceeded. Wait at least an hour.", Color.red);
			downloading_panel.hide();
			repo_info.text = "";
			return;
	
	for version in json.result:
		if (version.assets.size() == 0):
			continue;
		repo_data_dict.get(repo_data).append(version);
	#set_info_text("Found " + str(json.result.size()) + " online projects.", Color.black);
	
	for repo in repo_data_dict:
		if repo_data_dict.get(repo).size() == 0:
			print("Repo had no versions! Skipping: " + repo.name);
			repo_data_dict.erase(repo);
			return;
	
	if is_last:
		create_button_list();
		set_info_text("Found " + str(repo_data_dict.size()) + " online projects.", Color.black);
		downloading_panel.hide();

var button_group = ButtonGroup.new();
func create_button_list():
	var i = 0;
	for repo_data in repo_data_dict.keys():
		var list_button = Button.new();
		list_button.toggle_mode = true;
		list_button.group = button_group;
		list_button.text = repo_data.name;
		list_button.clip_text = true;
		list_button.align = Button.ALIGN_LEFT;
		$VBoxContainer/ScrollContainer/VBoxContainer.add_child(list_button);
	
		list_button.connect("pressed", self, "_on_ListButton_pressed", [repo_data, repo_data_dict.get(repo_data)]);
		i += 1;
	
	if button_group.get_buttons().size() != 0:
		button_group.get_buttons()[0].emit_signal("pressed");
		button_group.get_buttons()[0].pressed = true;

func _on_ListButton_pressed(repo_data, repo_versions):
	AppHandler.current_repo_data = repo_data;
	update_right_panel(repo_data, repo_versions);

func update_right_panel(repo_data, repo_versions):
	var text = "";
	text += "Name: " + repo_data.name;
	text += "\nCreated At: " + repo_data.created_at;
	text += "\nLast Updated At: " + repo_data.updated_at;
	text += "\nVersions: ";
	
	versions_option_button.clear();
	
	if repo_versions is Dictionary:
		if repo_versions.message:
			set_info_text("Github API rate limit exceeded. Wait at least an hour.", Color.red);
			downloading_panel.hide();
			return;
	
	for i in range(repo_versions.size() - 1, -1, -1):
		if repo_versions[i] != repo_versions[repo_versions.size() - 1]:
			text += ", "
		text += repo_versions[i].tag_name;
		versions_option_button.add_item(repo_versions[i].tag_name);
	repo_info.text = text;

func _on_DownloadButton_pressed():
	downloading_panel.show();
	
	var download_request = HTTPRequest.new();
	add_child(download_request);
	download_request.request("https://api.github.com/repos/benozzy1/" + AppHandler.current_repo_data.name + "/releases");
	download_request.connect("request_completed", self, "_on_DownloadRequest_request_completed");

var selected_release;
func _on_DownloadRequest_request_completed(result, response_code, headers, body):
	var json = JSON.parse(body.get_string_from_utf8());
	
	#print(json.result.assets[0].browser_download_url);
	#print(repo_data_dict.get(AppHandler.current_repo_data));
	for release in json.result:
		if versions_option_button.text == release.tag_name:
			selected_release = release;
			break;
	
	if !selected_release:
		set_info_text("Could not find a release to download.", Color.red);
		downloading_panel.hide();
		return;
	
	var games_folder_path = APP_PATH + "/games/";
	var dir = Directory.new();
	dir.open(games_folder_path);
	var current_dir = dir.get_current_dir();
	if !dir.dir_exists(current_dir + AppHandler.current_repo_data.name):
		set_info_text("Creating game folder...", Color.yellow);
		dir.make_dir(AppHandler.current_repo_data.name)
		print("Created game folder.");
	if !dir.dir_exists(current_dir + AppHandler.current_repo_data.name + "/versions"):
		set_info_text("Creating versions folder...", Color.yellow);
		dir.make_dir(AppHandler.current_repo_data.name + "/versions");
		print("Created versions folder.");
	if !dir.dir_exists(current_dir + AppHandler.current_repo_data.name + "/versions/" + selected_release.tag_name):
		set_info_text("Creating version folder...", Color.yellow);
		dir.make_dir(AppHandler.current_repo_data.name + "/versions/" + selected_release.tag_name);
		print(AppHandler.current_repo_data.name + "/versions/" + selected_release.tag_name);
		print("Created game version folder.");
	else:
		set_info_text("You already have this version installed!", Color.red);
		downloading = false;
		downloading_panel.hide();
		return;
	
	#var download_client = HTTPClient.new();
	#download_client.request();
	download_game(selected_release);

func download_game(selected_release):
	print("saving to: " + APP_PATH + "/games/" + AppHandler.current_repo_data.name + "/versions/" + selected_release.tag_name + "/" + selected_release.assets[0].name);
	download_request.download_file = APP_PATH + "/games/" + AppHandler.current_repo_data.name + "/versions/" + selected_release.tag_name + "/" + selected_release.assets[0].name;
	download_request.request(selected_release.assets[0].browser_download_url);
	set_info_text("Downloading file...", Color.black);
	downloading = true;

func _on_Download_completed(result, response_code, headers, body):
	set_info_text("Successfully downloaded " + AppHandler.current_repo_data.name + ".", Color.green);
	downloading = false;
	downloading_panel.hide();
	download_percent = 0;
	
	unzip_project(AppHandler.current_repo_data.name);
	
	refresh_local_tab();

func unzip_project(project_name):
	var base_dir = OS.get_user_data_dir() + "/games/" + project_name + "/versions/" + selected_release.tag_name;
	var file_name = base_dir + "/" + selected_release.assets[0].name;
	print(file_name);
	
	var read_file = File.new();
	if read_file.file_exists(file_name):
		read_file.open(file_name, File.READ);
		var content = read_file.get_buffer(read_file.get_len());
		read_file.close();
		
		var dir = Directory.new();
		dir.make_dir(base_dir + "/BRUH");
		
		var write_file = File.new();
		write_file.open(base_dir + "/BRUH", File.WRITE);
		write_file.store_buffer(content);
		write_file.close();


func _on_RefreshButton_pressed():
	refresh();

var has_refreshed = false;
func _on_TabContainer_tab_changed(tab):
	if tab == 1:
		info_label.show();
		if !has_refreshed:
			refresh();
			has_refreshed = true;
	else:
		info_label.hide();

func set_info_text(text, color):
	var label_node = info_label;
	label_node.set("custom_colors/font_color", color)
	label_node.text = text;

onready var local_tab = get_parent().get_node("Local");
func refresh_local_tab():
	local_tab.refresh();
