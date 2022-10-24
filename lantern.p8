pico-8 cartridge // http://www.pico-8.com
version 38
__lua__
function _init()
	cls()
	--	player coords
	x=-8
	y=104
	-- player sprite numbers
	front=37
	side=53
	back=21
	sprite_flip=false
	sprite_no=front
	-- player sprite offset
	pso=12
	-- move amount
	ma=2
	-- facing direction 
	facing=3
	dirs={
		{x=pso-8,y=pso},
		{x=pso+16,y=pso},
		{x=pso,y=pso-8},
		{x=pso,y=pso+16	},
	}
	-- look ahead
	la={
		-- left
		{
			p1x=pso-ma,
			p1y=pso,
			p2x=pso-ma,
			p2y=pso+8,
			dx=-ma,
			dy=0
		},
		-- right
		{
			p1x=pso+8,
			p1y=pso,
			p2x=pso+8,
			p2y=pso+8,
			dx=ma,
			dy=0
		},
		-- up
		{
			p1x=pso,
			p1y=pso-ma,
			p2x=pso+8,
			p2y=pso-ma,
			dx=0,
			dy=-ma
		},
		-- down
		{
			p1x=pso,
			p1y=pso+8,
			p2x=pso+8,
			p2y=pso+8,
			dx=0,
			dy=ma
		}
	}
	-- log2 table
	logs={0,1,0,2,0,0,0,3}
	--	floor tile coords
	ft=6
	ft_x=48
	ft_y=0
	-- orb tile numbers
	orb_tiles={
		empty=39,
		red=43,
		blue=41,
		yellow=45
	}
	--overwrite these
	overwrite={
		red={},
		blue={},
		yellow={}
	}
	--color map
	c_map={'red','blue','yellow'}
	--reverse map
	r_map={red=1,blue=2,yellow=3}
	--	current color 1/2/3
	rby=2
	--	palettes
	colors={}
	colors[1]={2,2,8,2,2,14,7,8,8,14,8,14,8,14,14,0}
	colors[2]={1,1,3,1,1,12,7,3,3,12,3,12,3,12,12,0}
	colors[3]={4,4,9,4,4,10,7,9,9,10,9,10,9,10,10,0}
	-- orb colors
	orbs={false,false,false}
	-- is player in wall?
	in_wall=false
	-- initial draw	
	draw_map()
end


function _draw()
	draw_map()
	draw_overwrites()
	illuminate()
	draw_player()
	pset(x+pso, y+pso, 11)
end


function _update()
		local neg=pso-ma
		local pos=pso+8
  if (btn(0)) then
  	facing=1
   sprite_no=side
   sprite_flip=false
			move(la[1])
  end
  if (btn(1)) then
  	facing=2
   sprite_no=side sprite_flip=true 
			move(la[2])
  end
  if (btn(2)) then
  	facing=3
   sprite_no=back
			move(la[3])
  end
  if (btn(3)) then
  	facing=4
   sprite_no=front
   move(la[4])
  end
  if (btnp(4)) and not in_wall then change_color() end
		if (btnp(5)) and not in_wall then activate_orb() end
end
-->8
function draw_map()
	map(0,0,0,0,16,16)
end


function draw_player()
	spr(sprite_no, x+pso,y+pso, 1, 1, sprite_flip)
end


function illuminate()
	--	mask coordinates
	ssx=0
	ssy=16
	for row=0,31 do
		for column=0,31 do
			--	grab pixel value of mask at this coordinate
		 local mask_v=(sget(ssx+column,ssy+row))
			--	if it's the mask color
		 if mask_v == 11 then
				--	get the map sprite at this location 
		 	local sprite_no=mget(flr((x+column)/8),flr((y+row)/8))
		 	local flag=fget(sprite_no)
		 	if flag == 2^rby then
					--	get the pixel value of that sprite at this coordinate
		 		local sprite_x=(ft_x+(column%8+x%8)%8)
		 		local sprite_y=(ft_y+(row%8+y%8)%8)
		 		sprite_v=sget(sprite_x,sprite_y)
		 	else
		 		sprite_v=pget(x+column,y+row)
		 	end
				--	shift palette
				pal(colors[rby])
				pset(x+column,y+row,sprite_v)
				pal()
		 end
		end
	end
end


function draw_overwrites()
	for c in pairs(overwrite) do
		for tile in all(overwrite[c]) do
			pal(colors[r_map[c]])
			for i=0,1 do
				for j=0,1 do
					spr(ft, (tile.x+i)*8, (tile.y+j)*8)
				end
			end
			pal()
		end 
	end
end
-->8
function is_solid(x,y)
	-- look ahead, get tile and flag
	local val=mget(flr(x/8),flr(y/8))
	local flag=fget(val)
	-- if tile matches color
	if flag == 2^rby then
		in_wall=true
		return false
	end
	-- if tile is floor
	if flag == 0 then
		in_wall=false
		return false
	end
	-- object is solid
	return true
end


function move(dir)
	local s1=is_solid(x+dir.p1x,y+dir.p1y)
	local s2=is_solid(x+dir.p2x,y+dir.p2y)
	if not s1 and not s2 then
		x=x+dir.dx
		y=y+dir.dy
	end
end


function change_color()
	-- return early if all orbs lit
	local all_lit=true
	for orb in all(orbs) do
		if not orb then all_lit = false end
	end
	if all_lit then return end
	
	rby=rby+1
	if rby == 4 then rby=1 end
	
	-- skip over orb colors
	while orbs[rby] do
		rby=rby+1
		if rby == 4 then rby=1 end
	end
end
-->8
function activate_orb()
	--check for orb
	local dir=dirs[facing]
	local xoff=flr((x+dir.x)/8)
	local yoff=flr((y+dir.y)/8)
	local tile=mget(xoff,yoff)
	local flag=fget(tile) 
	if flag % 2 == 1 then
		-- orb exists
		if flag > 1 then
			-- orb is full, retake flame
			local c=logs[flag-1]
			orbs[c]=false
			rby=c
			place_orb(xoff,yoff,'empty')
			rm_overwrites(c_map[c])
		else
			-- orb is empty, deposit flame
			orbs[rby]=true
			place_orb(xoff,yoff,c_map[rby])
			change_color()
		end
	end 
end


function place_orb(celx, cely, orb)
	if celx%2==0 then
		if cely%2==0 then
			startx=celx
			starty=cely
		else
			startx=celx
			starty=cely-1
		end
	else
			if cely%2==0 then
				startx=celx-1
				starty=cely
			else
				startx=celx-1
				starty=cely-1
			end
	end
	for i=0,1 do
		for j=0,1 do
			mset(startx+i,starty+j,orb_tiles[orb]+i+j*16)
		end
	end
	-- remove matching blocks
	if orb != 'empty' then
		add_overwrites(startx,starty,orb)	
	end
end


function add_overwrites(startx, starty, orb)
	-- check adjecent 4 or 8
	c_idx=r_map[orb]
	for i=-2,2,4 do
		-- add matching to overwrite
		local f1=fget(mget(startx+i,starty))
		local f2=fget(mget(startx,starty+i))
		if f1 == 2^c_idx or f1 == 0 then
			add(overwrite[orb],{x=startx+i,y=starty})
		end
		if f2  == 2^c_idx or f2 == 0 then
			add(overwrite[orb],{x=startx,y=starty+i})
		end
	end
end

function rm_overwrites(orb)
	overwrite[orb]={}
end
__gfx__
000000005555565500000bbbbbb00000000000000000000066656665e888888888888882c333333333333331a999999999999994000000000007000700000000
0000000055555655000bbbbbbbbbb0001214000000000000555555558e888888888888223c333333333333119a99999999999944000000007777777700000000
007007006666666600bbbbbbbbbbbb0022140000000000006566665688e888888888822233c333333333311199a9999999999444000000000700007000000000
00077000556555550bbbbbbbbbbbbbb0383900000000000055555555888eeeeeeeeee222333cccccccccc111999aaaaaaaaaa444000000007777777700000000
00077000556555550bbbbbbbbbbbbbb0421400000000000066656665888e88888888e222333c33333333c111999a99999999a444000000000007000700000000
0070070066666666bbbbbbbbbbbbbbbb521400000000000055555555888e8eeeeee8e222333c3cccccc3c111999a9aaaaaa9a444000000007777777700000000
0000000055555655bbbbbbbbbbbbbbbb6eca00000000000065666656888e8e8888e8e222333c3c3333c3c111999a9a9999a9a444000000000700007000000000
0000000055555655bbbbbbbbbbbbbbbb777700000000000055555555888e8e8888e8e222333c3c3333c3c111999a9a9999a9a444000000007777777700000000
0000000000000000bbbbbbbbbbbbbbbb883900000011110000000000888e8e8888e8e222333c3c3333c3c111999a9a9999a9a444000000000000000000000000
0000000000000000bbbbbbbbbbbbbbbb983900000777777000000000888e8e8888e8e222333c3c3333c3c111999a9a9999a9a444000000000000000000000000
0000000000000000bbbbbbbbbbbbbbbbaeca00007777777700000000888e8eeeeee8e222333c3cccccc3c111999a9aaaaaa9a444000000000000000000000000
00000000000000000bbbbbbbbbbbbbb0b83900007777777700000000888e88888888e222333c33333333c111999a99999999a444000000000000000000000000
00000000000000000bbbbbbbbbbbbbb0ceca00007777777700000000888eeeeeeeeee222333cccccccccc111999aaaaaaaaaa444000000000000000000000000
000000000000000000bbbbbbbbbbbb00d83900007777777700000000882222222222282233111111111113119944444444444944000000000000000000000000
0000000000000000000bbbbbbbbbb000eeca00000777777000000000822222222222228231111111111111319444444444444494000000000000000000000000
000000000000000000000bbbbbb00000feca00000011110000000000222222222222222811111111111111134444444444444449000000000000000000000000
000000000000bbbbbbbb0000000000000000000000111100555656556665666566656665ccc1ccc1ccc1ccc1eee2eee2eee2eee2aaa4aaa4aaa4aaa400000000
000000000bbbbbbbbbbbbbb000000000000000000777777056556556555555555555555511111111111111112222222222222222444444444444444400000000
0000000bbbbbbbbbbbbbbbbbb0000000000000007771c777656555656566677777766656c1ccc777777ccc1ce2eee777777eee2ea4aaa777777aaa4a00000000
000000bbbbbbbbbbbbbbbbbbbb00000000000000777cc77756556556555577777777555511117777777711112222777777772222444477777777444400000000
00000bbbbbbbbbbbbbbbbbbbbbb000000000000071777717555656556667776566777665ccc777cccc777cc1eee7778888777ee2aaa7779999777aa400000000
0000bbbbbbbbbbbbbbbbbbbbbbbb0000000000007711117756556556557775577557775511777cc77cc777112277788778877722447779977997774400000000
000bbbbbbbbbbbbbbbbbbbbbbbbbb0000000000007777770656555656577665667667756c177ccccc7cc771ce27788888788772ea47799999799774a00000000
00bbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000001111005655655655775555557577551177cccccc7c77112277888888787722447799999979774400000000
00bbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000111100000000006677666566757765cc77cccccc7c77c1ee778888887877e2aa779999997977a400000000
0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000077777700000000055775555555577551177cccccccc77112277888888887722447799999999774400000000
0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000007c777777000000006577765665677756c1777cccccc7771ce27778888887772ea47779999997774a00000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000071777777000000005557775555777555111777cccc7771112227778888777222444777999977744400000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000077177777000000006665777777776665ccc177777777ccc1eee277777777eee2aaa477777777aaa400000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000001177777700000000555557777775555511111777777111112222277777722222444447777774444400000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000007777770000000006566665665666656c1cccc1cc1cccc1ce2eeee2ee2eeee2ea4aaaa4aa4aaaa4a00000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000011110000000000555555555555555511111111111111112222222222222222444444444444444400000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bbbbbbbbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00bbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00bbbbbbbbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000bbbbbbbbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000bbbbbbbbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000bbbbbbbbbbbbbbbbbbbbbb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000bbbbbbbbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000bbbbbbbbbbbbbbbbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000bbbbbbbbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000bbbbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0001000000000002020404080800000000000000000000020204040808000000000000000000000101050503030909000000000000000001010505030309090000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0b0c0b0c0b0c0b0c090a090a0b0c060600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1b1c1b1c1b1c1b1c191a191a1b1c060600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07082728090a07080708090a0b0c0b0c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
17183738191a17181718191a1b1c1b1c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
070806060b0c07082728090a0b0c060600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
171806061b1c17183738191a1b1c060600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0708090a0b0c0708090a090a0b0c070800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1718191a1b1c1718191a191a1b1c171800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0708090a090a07080b0c090a090a070800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1718191a191a17181b1c191a191a171800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0708090a2728090a0b0c090a0606070800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1718191a3738191a1b1c191a0606171800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06060606060607080b0c0b0c0708070800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06060606060617181b1c1b1c1718171800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
060606060606090a090a090a090a070800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
060606060606191a191a191a191a171800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
