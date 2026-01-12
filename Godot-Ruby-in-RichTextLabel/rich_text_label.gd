extends RichTextLabel

# 翻訳キーを変数に保存
@export var translation_key: String


func _ready()-> void:
	bbcode_enabled = true
	
	#RichTextLabelにアタッチされてる前提
	var _Rabelnode = self
	self.text = auto_convert_to_ruby(self.text,_Rabelnode)
	
	#多言語切り替えしたい時
	#if translation_key.is_empty():
		#translation_key = self.text
	#_on_language_changed()

func _on_language_changed():
	# ... （フォント切り替え処理などを省略） ...

	if !translation_key.is_empty():
		var translated_text = tr(translation_key)
		# auto_convert_to_ruby 関数を呼び出す際に、自分自身 (self) を渡す
		var ruby_text = auto_convert_to_ruby(translated_text, self)
		
		# 最終的なテキストをセット
		self.text = ruby_text 




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
	#ここで　漢字(ふりがな)を確認してるので変更したい場合はここを変更。
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
