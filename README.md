# Godot-Ruby-in-RichTextLabel
Godot 4.x RichTextLabel で擬似的均等配置ルビを実現する方法

・漢字（ふりがな）　の形式でルビを付ける関数です。
・適宜richTextLabelのスクリプトに追加してtextを変換させてください。


<img width="324" height="84" alt="sample-1" src="https://github.com/user-attachments/assets/53c10dcb-18b6-4620-a321-5f02915c87a5" />

＃グーグルAIと相談とトライ＆エラーを繰り返して作りました。
bbcodeでの解決案は色々頑張りましたが、結局うまくいかなかったので
tableタグを利用する方法としてbruvzgさんのレスを参考にしました。
https://github.com/godotengine/godot-proposals/issues/12316#issuecomment-2830913785




＃＃＃＃＃＃＃＃＃＃＃＃＃＃＃＃＃＃＃＃＃＃＃＃＃＃＃＃＃＃＃＃＃＃＃＃＃＃＃＃＃＃＃＃＃＃＃＃＃＃＃

extends RichTextLabel

func _ready()-> void:
	bbcode_enabled = true
	
	#RichTextLabelにアタッチされてる前提
	var _Rabelnode = self
	self.text = auto_convert_to_ruby(self.text,_Rabelnode)



####変換

	func auto_convert_to_ruby(input_text: String, label: RichTextLabel = null) -> String:
		var ruby_size = 14
		var current_size = 28
	
		if label:
			# 現在のフォントサイズを取得し、ルビサイズ（半分のサイズ）を計算
			#　サイズ調整したい場合は適当にいじって。
			current_size = label.get_theme_font_size("normal_font_size")
			ruby_size = int(current_size / 2.0)

		var regex = RegEx.new()
		# 正規表現: 漢字1文字以上と、括弧内のふりがなを抽出
		#ここで　漢字(ふりがな)の形式を確認してるので変更したい場合はここを変更。
		#漢字以外を使いたい時とか別のタグを使いたいとか。
		regex.compile("([\\x{4E00}-\\x{9FAF}]+)[（\\(]([^）\\)]+)[）\\)]")
		
		var results = regex.search_all(input_text)
		var output_text = input_text
	
		# 後ろから置換することで、文字列インデックスのズレを防ぐ
		results.reverse()
		for res in results:
		var kanji = res.get_string(1) # 抽出した漢字
		var yomi = res.get_string(2)  # 抽出したふりがな
		
		var formatted_yomi = yomi
		
		# 漢字の長さ * 1.5 > ふりがなの長さ の場合にスペースを挿入して均等配置ぽくした
		# 逆にふりがなが漢字幅を超える場合、漢字の前後にスペースができるけど読めるので許して。
		#または長くなりすぎたらフォントサイズを変更するとかしてください。
		if kanji.length() * 1.5 > yomi.length() and yomi.length() > 1:
			var space_count = int(kanji.length() * 1.5 - yomi.length())
			var space_str = ""
			for i in range(space_count):
				# [font_size]でサイズ指定した半角スペースを挿入
				space_str += "[font_size=%d] [/font_size]" % ruby_size 
			
			formatted_yomi = ""
			for i in range(yomi.length()):
				formatted_yomi += yomi[i]
				if i < yomi.length() - 1:
					formatted_yomi += space_str
		
		# [table]タグで上下に配置し、[center]タグで中央寄せ
		var replacement = "[table=1,baseline,baseline,1][cell][center][font_size=%d]%s[/font_size][/center][/cell][cell][center]%s[/center][/cell][/table]" % [ruby_size, formatted_yomi, kanji]
		#print(replacement)
		output_text = output_text.erase(res.get_start(), res.get_end() - res.get_start())
		output_text = output_text.insert(res.get_start(), replacement)

		return output_text
