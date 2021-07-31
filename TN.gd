extends Node2D

# generated using inkscape --query-all tndistricts.svg
var d={
	Ariyalur=[953.4,772.77154],
	Chengalpattu=[1187.6992,250.59959],
	Chennai=[1346.5329,127.77688],
	Coimbatore=[176.59072,778.52605],
	Cuddalore=[930,608],
	Dharmapuri=[523.4,391.98666],
	Dindigul=[378.9,976.16227],
	Erode=[239.74398,586.9],
	Kallakurichi=[845.71773,541.92189],
	Kanchipuram=[1159.6992,209.4353],
	Kanyakumari=[318.8,1749.4],
	Karur=[548.7041,882.19391],
	Krishnagiri=[447.84352,264.0834],
	Madurai=[448.7,1155.6],
	Mayiladithurai=[1147.2,766.3],
	Nagapattinam=[1190.8322,941.2],
	Namakkal=[525.9,710.24797],
	Nilgiris=[35.179205,666.66965],
	Perumbalur=[849.59825,736.1],
	Pudukotai=[784,1010.1992],
	Ramanathapuram=[711.41374,1277.6],
	Ranipet=[1035.4198,153.59961],
	Salem=[510.87492,581.5356],
	Sivagangai=[670.3,1117.9],
	Tenkasi=[342.68731,1464.2479],
	Thanjavur=[892.9,849.9625],
	Theni=[349.98068,1189.1748],
	Thoothukudi=[524.26323,1477.0951],
	Tiruchirapalli=[687.5,771.2813],
	Tirunelveli=[342.5811,1598.9395],
	Tirupathur=[769.5,237.28516],
	Tiruppur=[295.39381,797.44396],
	Tiruvallur=[1066.8503,31.7],
	Tiruvannamalai=[844.8954,260.51825],
	Tiruvarur=[1067.9132,907.08195],
	Vellore=[833.79688,171.82608],
	Vilippuram=[1042.3355,412.88469],
	Virudhunagar=[406.3,1340.1006]
}

var score=0
var attempts=0
var turns=10
var game_in_progress=false
var rng=RandomNumberGenerator.new()

var challenge:=''
var selected_district:=''
var selected_color:=Color.darkorange
var deselect_color:=Color.lightyellow#Color("eeffcc88")
var selected_color_right:=Color.lightgreen
var selected_color_wrong:=Color.lightcoral
var border_color
var border_width

func create_polygons(s:Sprite):
	var b=BitMap.new()
	b.create_from_image_alpha(s.texture.get_data())	
	var rect=Rect2(0, 0, s.texture.get_width(), s.texture.get_height())
	var polys=b.opaque_to_polygons(rect)
	var p=Polygon2D.new()
	var c=CollisionPolygon2D.new()
	p.polygon=polys[0]
	p.position=s.position - Vector2(s.texture.get_width()/2.0,s.texture.get_height()/2.0)
	p.color=deselect_color
	c.polygon=polys[0]
	c.position=s.position - Vector2(s.texture.get_width()/2.0,s.texture.get_height()/2.0)
	return [c, p]

func _ready():
	rng.randomize()
	VisualServer.set_default_clear_color(Color("ff000000"))
	for district in d.keys():
		var a2d=Area2D.new()
		var x=d[district][0]
		var y=d[district][1]
		var s=Sprite.new()
		var image=load("res://"+district+".png")
		s.texture=image
		var w=s.texture.get_width()
		var h=s.texture.get_height()
		d[district].append(w)
		d[district].append(h)
		var polys=create_polygons(s)
		a2d.add_child(polys[1])
		a2d.add_child(polys[0])
		a2d.name=district
		a2d.show_behind_parent=true
		a2d.position=Vector2(x+(w/2),y+(h/2))
		add_child(a2d)
		a2d.connect('input_event', self, 'on_district_select',[district])
		
	$Camera2D.position=get_node('Karur').position
	$Camera2D.zoom=Vector2(2.4, 2.4)
	update()

func _unhandled_input(event):
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_ESCAPE:
			get_tree().quit()
		
func on_district_select(viewport, event, idx, district):
	if event is InputEventMouseButton and event.pressed:
		select(district)

func select(district):
	if game_in_progress:
		if district == challenge:
			score+=1
			attempts+=1
			$HUD/Score.text=str(score)+' / '+str(attempts)
			get_node(district).get_child(0).color=selected_color_right
			$HUD/Label.text=district
			var gpos=get_node(district).position
			$HUD/Label.rect_global_position =Vector2(330,0)+ gpos/($Camera2D.zoom) 
			timed_msg("Correct!", 2)
			yield($Timer, "timeout")
			if attempts < turns:
				new_challenge()
		else:
			attempts+=1
			$HUD/Score.text=str(score)+' / '+str(attempts)
			get_node(district).get_child(0).color=selected_color_wrong
			$HUD/Message.text='That was '+district
		if attempts==turns:
			timed_msg('Not bad! \nYou scored '+str(score)+' / '+str(attempts),3)
			yield($Timer, "timeout")
			game_in_progress=false
			game_over()
	else:
		#deselect district if one is already selected before selecting new one
		#selecting = change color + add border
		if district!=selected_district and selected_district!='':
			deselect()
		selected_district=district
		$HUD/Label.text=district
		var gpos=get_node(selected_district).position
		$HUD/Label.rect_global_position =Vector2(330,0)+ gpos/($Camera2D.zoom) 
		var poly=get_node(selected_district).get_child(0)
		poly.color=selected_color
		#selected_district_border_pts=PoolVector2Array(poly.polygon)
		update()
				
func deselect():
	get_node(selected_district).get_child(0).color=deselect_color

func _draw():
	for i in d.keys():
		var poly=PoolVector2Array(get_node(i).get_child(0).polygon)
		if i == selected_district:
			draw_border(poly, i, true)
		else:
			draw_border(poly, i, false)
			
func draw_border(poly:PoolVector2Array, dist:String, selected:bool):
	var cnt=poly.size()
	var center_at=Vector2(d[dist][0], d[dist][1])
	if selected:
		border_color=Color.black
		border_width=5
	else:
		border_color=Color.black
		border_width=2 
	for i in range(1, cnt):
		draw_line(poly[i-1]+center_at, poly[i]+center_at, border_color, border_width )
	draw_line(poly[cnt-1]+center_at, poly[0]+center_at, border_color, border_width )
	
func _on_Button_pressed():
	$HUD/Button.hide()
	$HUD/Learn.hide()
	start_game()

func start_game():
	score=0
	attempts=0
	game_in_progress=true
	$HUD/Score.text=str(score)
	$Timer.start()
	$HUD/Message.text="You have 10 turns\n Find the Districts!"
	yield($Timer,"timeout")
	new_challenge()

func new_challenge():
	challenge=d.keys()[rng.randi_range(0,len(d)-1)]
	$HUD/Message.text=challenge+" ???"

func game_over():
	$HUD/Score.text=''
	$HUD/Message.text=''
	$HUD/Button.show()
	$HUD/Learn.show()

func timed_msg(msg, showafter):
	$Timer.wait_time=showafter
	$Timer.start()
	$HUD/Message.text=msg
