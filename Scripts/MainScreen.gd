extends Control

#curl -s https://api.github.com/repos/benozzy1/Godot-3D-Fast-Paced-Shooter/releases/latest \
					  #| grep browser_download_url \
					  # grep Build1 \
					  #| cut -d '"' -f 4

func _ready():
	$HTTPRequest.connect("request_completed", self, "_on_request_completed");

func _on_Button_pressed():
	$HTTPRequest.request("https://api.github.com/repos/benozzy1/Godot-3D-Fast-Paced-Shooter/releases/latest");
	
func _on_request_completed(result, response_code, headers, body):
	var json = JSON.parse(body.get_string_from_utf8());
	print(json.result.assets[0].browser_download_url);
