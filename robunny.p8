pico-8 cartridge // http://www.pico-8.com
version 18
__lua__


global = {
 mapsize = 16,
 current_level = 1,
 difficulty = 1,
 score = 0,
 carrot_left = 0,
 state = 0, -- 0 for menu, 1 for game
 steps = 0,
 step_overflow_1 = 0,
 step_overflow_2 = 0,
 brw_movement = 0
}

trees = {1,2,3,4}
grounds = {5,6,7,8}
burrow = 9
burrow_highlight = 10

season = 3 -- 1 summer, 2 fall, 3 winter, 4 spring
season_duration = 50
next_season = 0
seasonal_movement = {2,2,2,2}
seasonal_burrows = {0.05,0.04,0.05,0.01}
seasonal_carrots = {0.05,0.02,0.01,0.03}
seasonal_change = 0

pressed_button = 0
lost = 0
carrot = 63
paw = 48

wolves={}
burrows={}

player={
  x = -1,
  y = -1,
  placed = 0
}
idx = 1
old_idx = 1
selecting = 0
stats = 0

function _init()
 -- export("music.wav")
 --music(0)
  menuitem(2,"stats", show_stats)
end

function show_stats()
  stats = 1
end

function init_game()

  lost = 0
  wolves = {}
  burrows = {}
  player.x = -1
  player.y = -1
  player.placed = 0
  global.carrot_left = 0
  
  calculate_seasons()
  cls()

  for x=0,global.mapsize-1 do
    for y=0,global.mapsize-2 do
      mset(x,y,trees[season])
    end
  end
  dig(0,0,0.5,400)
  dig(8,8,0.5,400)
  dig(4,4,0.5,100)
  place_rabbit_holes(seasonal_burrows[season])
  place_carrots(seasonal_carrots[season])

  for x=0,global.mapsize-1 do
    for y=0,global.mapsize-2 do
      if mget(x,y) == carrot then
        global.carrot_left += 1
      end
    end
  end
  place_wolves(0.05)
  place_player()
  if (global.steps > 1) and ((global.steps%100) == 0) then
    season += 1
    if season > 4 then
      season = 1
    end
  end
end

function place_rabbit_holes(probability)
  for x=0,global.mapsize-1 do
    for y=0,global.mapsize-2 do
      rng = rnd(1)
      if (rng <= probability) and (mget(x,y) == grounds[season]) then
        local brw = {
          x = x,
          y = y
        }
        add(burrows,brw)
        mset(x,y,burrow)
      end
    end
  end
end

function place_carrots(probability)
  carrot_number = 0
  while carrot_number < (3 + flr(global.current_level/5)) do
    for x=0,global.mapsize-1 do
      for y=0,global.mapsize-2 do
        rng = rnd(1)
        if (rng <= probability) and (mget(x,y) == grounds[season]) then
          mset(x,y,carrot)
          carrot_number += 1
        end
      end
    end
  end
end

function place_wolves(probability,season_multiplier)
  local wolf_number
  if season == 3 then
    wolf_number = flr((global.current_level/5) + global.difficulty)/2
    if wolf_number < 1 then 
      wolf_number = 1
    end
  else
   wolf_number = flr((global.current_level/5) + global.difficulty)
  end
  while #wolves <= wolf_number do
    x_rand = flr(rnd(15)) + 1
    y_rand = flr(rnd(14)) + 1
    if not ((x_rand < 0) or (x_rand > 15) or (y_rand < 0) or (y_rand > 14)) then
      rng = rnd(1)
      if (rng <= probability) and (mget(x_rand,y_rand) == grounds[season]) then
        local wolf = {
          x = x_rand,
          y = y_rand,
          spr = 33
        }
        add(wolves,wolf)
      end
    end
  end
end

function place_player()
  while not (player.placed == 1) do
    x_rand = flr(rnd(15)) + 1
    y_rand = flr(rnd(14)) + 1
    if not ((x_rand < 0) or (x_rand > 15) or (y_rand < 0) or (y_rand > 14)) then
      if (mget(x_rand,y_rand) == burrow) then
        player.x = x_rand
        player.y = y_rand
        player.placed = 1
      end
    end
  end
end

function dig(x_start,y_start,t,s)
  turn_chance = t
  steps = s
  done = 0
  outside = true
  x = x_start
  y = y_start
  while outside do
    x = x_start
    y = y_start
    if ((x < 0) or (x > 15) or (y < 0) or (y > 14)) then
      outside = true
    else
     outside = false
    end
  end

  outside = true

  while (done <= steps) do
    while outside do
      turn = rnd(1)

      if turn < turn_chance then -- nem fordulok
          vertical = rnd(1)
          if vertical < 0.5 then
            if not (y+1 > 14) then 
              y = y + 1
            end
          else
            if not (y-1 < 0) then 
              y = y - 1
            end
          end
      else
         horizontal = rnd(1) -- fordulok
          if horizontal < 0.5 then
            if not (x+1 > 15) then 
              x = x + 1
            end
          else
            if not (x-1 < 0) then 
              x = x - 1
            end
          end
      end

      if ((x < 0) or (x > 15) or (y < 0) or (y > 14)) then
        outside = true
      else
       outside = false
      end
    end
    done = done + 1
    draw = rnd(1)
    mset(x,y,grounds[season])
    outside = true
  end
end


function check_carrot()
  if (mget(player.x,player.y) == carrot) then
    sfx(0)
    mset(player.x,player.y,grounds[season])
    global.score +=1
    global.carrot_left -= 1
  end
end

function line_of_sight(x0,y0,x1,y1)

  if(mget(x0,y0) == burrow) then
    return false
  end

  local sx,sy,dx,dy

  if x0 < x1 then
    sx = 1
    dx = x1 - x0
  else
    sx = -1
    dx = x0 - x1
  end

  if y0 < y1 then
    sy = 1
    dy = y1 - y0
  else
    sy = -1
    dy = y0 - y1
  end

  local err, e2 = dx-dy, nil

  if (mget(x0, y0) == trees[season]) then return false end

  while not(x0 == x1 and y0 == y1) do
    e2 = err + err
    if e2 > -dy then
      err = err - dy
      x0  = x0 + sx
    end
    if e2 < dx then
      err = err + dx
      y0  = y0 + sy
    end
    if (mget(x0, y0) == trees[season]) then return false end
  end

  return true
end

function move_wolves()
  for wolf in all(wolves) do
    if wolf_sight(wolf) then
      wolf.path = find_path(wolf, player,
                  manhattan_distance,
                  flag_cost,
                  map_neighbors,
                  function (node) return shl(node.y, 8) + node.x end,
                  nil)
      if not (wolf.path == nil) then
        length = #wolf.path
        if (length > 0) then
          dest = wolf.path[length-1]
          wolf.x = dest.x
          wolf.y = dest.y
        elseif (length == 1) then
          dest = wolf.path[length]
          wolf.x = dest.x
          wolf.y = dest.y
        end
      end
    else
      outside = true
      step_x = 0
      step_y = 0
      rng = rnd(1)

      -- x < 0.5 ia horizontal, bigger is vertical
      -- second random, smaller is negative, bigger is positive
      
      while outside do
        step_x = 0
        step_y = 0
        if rng < 0.5 then -- move horizontaly
          rng = rnd(1)
          if rng < 0.5 then
            step_x = -1
          else
            step_x = 1
          end
        else              -- move vertically
          rng = rnd(1)
          if rng < 0.5 then
            step_y = -1
          else
            step_y = 1
          end
        end
     
        if ((wolf.x+step_x < 0) or (wolf.x+step_x > 15) or (wolf.y+step_y < 0) or (wolf.y+step_y > 14)) then
          outside = true
        else
          if not (mget(wolf.x+step_x,wolf.y+step_y) == trees[season]) then
           outside = false
          end
          end
        end
      wolf.x += step_x
      wolf.y += step_y
    end
    if (player.x == wolf.x) and (player.y == wolf.y) then
      if not (mget(player.x,player.y) == burrow) then
        lost = 1
      end
    end
  end
end

function wolf_sight(wolf)
  if (line_of_sight(player.x,player.y,wolf.x,wolf.y)) then
    wolf.spr = 33
    return true
  else
    wolf.spr = 32
    return false
  end
  --printh(line_of_sight(player.x,player.y,wolf.x,wolf.y))
  return false
end

function find_path
(start,
 goal,
 estimate,
 edge_cost,
 neighbors, 
 node_to_id, 
 graph)
 
 -- the final step in the
 -- current shortest path
 local shortest, 
 -- maps each node to the step
 -- on the best known path to
 -- that node
 best_table = {
  last = start,
  cost_from_start = 0,
  cost_to_goal = estimate(start, goal, graph)
 }, {}

 best_table[node_to_id(start, graph)] = shortest

 -- array of frontier paths each
 -- represented by their last
 -- step, used as a priority
 -- queue. elements past
 -- frontier_len are ignored
 local frontier, frontier_len, goal_id, max_number = {shortest}, 1, node_to_id(goal, graph), 32767.99

 -- while there are frontier paths
 while frontier_len > 0 do

  -- find and extract the shortest path
  local cost, index_of_min = max_number
  for i = 1, frontier_len do
   local temp = frontier[i].cost_from_start + frontier[i].cost_to_goal
   if (temp <= cost) index_of_min,cost = i,temp
  end
 
  -- efficiently remove the path 
  -- with min_index from the
  -- frontier path set
  shortest = frontier[index_of_min]
  frontier[index_of_min], shortest.dead = frontier[frontier_len], true
  frontier_len -= 1

  -- last node on the currently
  -- shortest path
  local p = shortest.last
  
  if node_to_id(p, graph) == goal_id then
   -- we're done.  generate the
   -- path to the goal by
   -- retracing steps. reuse
   -- 'p' as the path
   p = {goal}

   while shortest.prev do
    shortest = best_table[node_to_id(shortest.prev, graph)]
    add(p, shortest.last)
   end

   -- we've found the shortest path
   return p
  end -- if

  -- consider each neighbor n of
  -- p which is still in the
  -- frontier queue
  for n in all(neighbors(p, graph)) do
   -- find the current-best
   -- known way to n (or
   -- create it, if there isn't
   -- one)
   local id = node_to_id(n, graph)
   local old_best, new_cost_from_start =
    best_table[id],
    shortest.cost_from_start + edge_cost(p, n, graph)
   
   if not old_best then
    -- create an expensive
    -- dummy path step whose
    -- cost_from_start will
    -- immediately be
    -- overwritten
    old_best = {
     last = n,
     cost_from_start = max_number,
     cost_to_goal = estimate(n, goal, graph)
    }

    -- insert into queue
    frontier_len += 1
    frontier[frontier_len], best_table[id] = old_best, old_best
   end -- if old_best was nil

   -- have we discovered a new
   -- best way to n?
   if not old_best.dead and old_best.cost_from_start > new_cost_from_start then
    -- update the step at this
    -- node
    old_best.cost_from_start, old_best.prev = new_cost_from_start, p
   end -- if
  end -- for each neighbor
  
 end -- while frontier not empty

 -- unreachable, so implicitly
 -- return nil
end

function draw_path(path, dy, clr)
 local p = path[1]
 for i = 2, #path do
  local n = path[i]
  line(p.x * 8 + 4 + dy, p.y * 8 + 4 + dy, n.x * 8 + 4 + dy, n.y * 8 + 4 + dy, clr)
  p = n
 end
end

-- makes the cost of entering a
-- node 4 if flag 1 is set on
-- that map square and zero
-- otherwise
function flag_cost(from, node, graph)
 return fget(mget(node.x, node.y), 1) and 4 or 1
end


-- returns any neighbor map
-- position at which flag zero
-- is unset
function map_neighbors(node, graph)
 local neighbors = {}
 if (not fget(mget(node.x, node.y - 1), 0)) add(neighbors, {x=node.x, y=node.y - 1})
 if (not fget(mget(node.x, node.y + 1), 0)) add(neighbors, {x=node.x, y=node.y + 1})
 if (not fget(mget(node.x - 1, node.y), 0)) add(neighbors, {x=node.x - 1, y=node.y})
 if (not fget(mget(node.x + 1, node.y), 0)) add(neighbors, {x=node.x + 1, y=node.y})
 return neighbors
end

-- estimates the cost from a to
-- b by assuming that the graph
-- is a regular grid and all
-- steps cost 1.
function manhattan_distance(a, b)
 return abs(a.x - b.x) + abs(a.y - b.y)
end

function calculate_seasons()
  if (global.steps > next_season) then
    next_season = global.steps + season_duration
    season += 1
    seasonal_change = 1
    if season > 4 then
      season =1
    end
  end
end

function calculate_difficulty()
  global.difficulty = 1 + (global.steps/100) + (global.step_overflow_1*100) + (global.step_overflow_2*1000) + global.brw_movement
end


function _update()
  --printh("lost: "..lost.." state: "..global.state)
  if global.state == 0 then
    if btnp(4) then
      season = 1
      global.difficulty = 1
      global.state = 1
      steps = 0
      step_overflow_1 = 0
      step_overflow_2 = 0
      global.score = 0
      init_game()
    end
  else
    if not (lost == 1) then
    
      if stats == 1 then
        if btnp(4) then
          stats = 0
        end
      elseif selecting == 1 then 
        mset(burrows[idx].x,burrows[idx].y,burrow)
        if btnp(0) then
          idx -= 1
          if (idx < 1) idx = #burrows
        elseif btnp(1) then
          idx += 1
          if (idx > #burrows) idx = 1
        end
        if btnp(4) then
          global.brw_movement += 0.2
          selecting = 0
          mset(burrows[idx].x,burrows[idx].y, grounds[season])
          player.x = burrows[idx].x
          player.y = burrows[idx].y
          del(burrows,burrows[idx])
        else
          mset(burrows[idx].x,burrows[idx].y,burrow_highlight)
        end
        if btnp(5) then
          local brw = {
            x = player.x,
            y = player.y
          }
          add(burrows,brw)
          mset(player.x,player.y,burrow)
          mset(burrows[idx].x,burrows[idx].y,burrow)
          selecting = 0
        end
      elseif seasonal_change == 1 then
        if btnp(4) then
          seasonal_change = 0
        end
      else
        calculate_difficulty()

        if global.steps > 3270 then
          global.steps = 0
          global.step_overflow_1 += 1
        end
        if global.step_overflow_1 > 3270 then
          global.step_overflow_1 = 0
          global.step_overflow_2 += 1
        end

        new_x = player.x
        new_y = player.y
        --printh("miva")
        -- player turn for up to two movement
  --       if btnp(4) then
  --        season += 1
  --          if season > 4 then
  --            season = 1
  --          end
  --          init_game()
  --        end
          if btnp(5) then
            pressed_button +=1
            global.steps +=1
          elseif btnp(0) then
            new_x = player.x - 1
            pressed_button +=1
            global.steps +=1
          elseif btnp(1) then
            new_x = player.x + 1
            pressed_button +=1
            global.steps +=1
         elseif btnp(2) then
            new_y = player.y - 1
            pressed_button +=1
            global.steps +=1
         elseif btnp(3) then
            new_y = player.y + 1
            pressed_button +=1
            global.steps +=1
          end
          if (mget(player.x,player.y) == burrow) or (mget(player.x,player.y) == burrow_highlight) then
            if btnp(4) then
              mset(player.x,player.y,grounds[season])
              for brw in all(burrows) do
                if (player.x == brw.x) and (player.y == brw.y) then
                  del(burrows,brw)
                end
              end
              selecting = 1
              idx = 1
              old_idx = 1
            end
          end

        -- move player if valid movement
        if (not (mget(new_x,new_y) == trees[season])) then
          if not ((new_x < 0) or (new_x > 15) or (new_y < 0) or (new_y > 14)) then
            player.x = new_x
            player.y = new_y
          end
        end

       for wolf in all(wolves) do
          if (player.x == wolf.x) and (player.y == wolf.y) then
            if not (mget(player.x,player.y) == burrow) then    
              lost = 1
            end
          end
        end

        -- move enemies if player did 2 steps
        while (pressed_button == seasonal_movement[season]) and not (lost == 1) do
          move_wolves()
          pressed_button = 0
        end

        check_carrot()

        if(global.carrot_left == 0) then
        global.current_level += 1
          init_game()
        end

        for wolf in all(wolves) do
          wolf_sight(wolf)
        end
      end
    else
      if btnp(4) then
        lost = 0
        global.state = 0
        carrot_left = 0
        global.current_level = 1
        global.score = 0
        global.steps = 0
        global.step_overflow_1 = 0
        global.step_overflow_2 = 0
      end
    end
  end
end

function _draw()
  if lost == 1 then
      rectfill(32,32,102,91,7)
      rectfill(33,33,101,90,0)
      print("you got eaten: ",38,34,8)
      rectfill(33,42,102,42,7)
      print("score: "..global.score,34,44,7)
      print("diff: "..global.difficulty,34,53,7)
      print("steps: "..global.steps,34,62,7)
      local s
      if season == 1 then
        s = "summer"
      elseif season == 2 then
        s = "fall"
      elseif season == 3 then
        s = "winter"
      elseif season == 4 then
        s = "spring"
      end
      print("season: "..s,34,71,7)
      if(time()%2 < 1) then
        print("- \142 -",55,80,8)
      end
  else
    cls()
    if global.state == 0 then
      draw_menu()
    else
      map()
      for wolf in all(wolves) do
        spr(wolf.spr,wolf.x*8,wolf.y*8)
      end
      if(mget(player.x,player.y) == 3) then
        spr(17,player.x*8,player.y*8)
      else
        spr(16,player.x*8,player.y*8)
      end
      for paw in all(paws) do
        spr(paw.spr,paw.x,paw.y)
      end
      draw_ui()

    end
  end
end

function draw_ui()
  if selecting == 1 then
    print("⬅️➡️:prv/nxt",0,120,9)
    print("|",52,120,7)
    print("\142:select",56,120,9)
    print("|",92,120,7)
    print("\151:exit",96,120,9)
  elseif seasonal_change == 1 then
    rectfill(32,32,102,91,7)
    rectfill(33,33,101,90,0)
    print("season info: ",38,34,9)
    rectfill(33,42,102,42,7)

    if season == 1 then
      print("avg burrows",34,44,7)
      print("avg carrots",34,54,7)
      print("avg wolves",34,64,7)
    elseif season == 2 then
      print("less burrows",34,44,7)
      print("less carrots",34,54,7)
      print("less wolves",34,64,7)
    elseif season == 3 then
      print("less burrows",34,44,7)
      print("least carrots",34,54,7)
      print("less wolves",34,64,7)
    elseif season == 4 then
      print("least burrows",34,44,7)
      print("less carrots",34,54,7)
      print("least wolves",34,64,7)
    end
    print("- \142 -",55,80,9)
  else
    print("ate: "..global.score,0,120,9)
    print("|",38,120,7)
    print("lvl: "..global.current_level,42,120,9)
    print("|",72,120,7)
    print("left: "..global.carrot_left,76,120,9)
    print("| "..pressed_button,110,120,7)
    --print("step: "..pressed_button,96,120,9)
  end
  if stats == 1 then
    rectfill(32,32,102,91,7)
    rectfill(33,33,101,90,0)
    print("current status: ",38,34,9)
    rectfill(33,42,102,42,7)
    print("score: "..global.score,34,44,7)
    print("diff: "..global.difficulty,34,53,7)
    print("steps: "..global.steps,34,62,7)
    local s
    if season == 1 then
      s = "summer"
    elseif season == 2 then
      s = "fall"
    elseif season == 3 then
      s = "winter"
    elseif season == 4 then
      s = "spring"
    end
    print("season: "..s,34,71,7)
    print("- \142 -",55,80,9)
  end
end

function draw_menu()
  spr(64,20,20,4,4)

  print("crazy",80,24,9)
  print("rabbit",79,32,9)
  print("afternoon",73,40,9)


  if(time()%2 < 1) then
    print("press \142 to play",25,72,3)
  end


  print("wasd - move 1",32,84,4)
  print("\151 - skip 1 move",24,92,4)
  print("wolves move 1 after you move 2",0,100,4)
  print("wolves can't see you in holes",2,108,4)
  rectfill(0,118,128,118,1)
  print(" made by: bela toth - achie72",4,120,3)



end


__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000003030000040900000706000009030000003000000050000000600000004000000000000000000000000000000000000000000000000000000000
00700700000000030000000900000006000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000030303330409099907060666080303330300000005000000060000000300000000055000000990000000000000000000000000000000000000000000
00077000000300400009004000060040000300400000400000004000000050000000500000500500009009000000000000000000000000000000000000000000
00700700033300400999004006660040033300400000000000000000000000000000000000500500009009000000000000000000000000000000000000000000
00000000004000000040000000400000004000000000000000000000000000000000000005055050090990900000000000000000000000000000000000000000
00000000004000000040000000400000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0077077000dd0dd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070000d00d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070000d00d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0077770000dddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070700000d0d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0077070000dd0d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0077770000dddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000800008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000880088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00220220008808800880088000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020200000808008088880800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00202020008080808008800800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00222220008888800888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020200000808000080080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00002000000080000008800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bb000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000b0000
00002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00200020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000990000
00002000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090000
00022200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000090000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007777707777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077777777667777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077666777666677000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00076666677766677700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00006666667776667700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000666666777667700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000066666677667770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000666677777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000066777777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000067777777767700000bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077777677676770000bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077776767777770330bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000067777777777770330b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000677777776777bb30b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000067777777760bb3bb00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000006766677766700b3b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000067777766677770b3b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000067777777777777999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000067777777777777777600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000677777766677777776700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000677777777667777777600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000677777777776666699900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000677777666677770999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007770677776777767770999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077777677767777776770999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077777677767777777670999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007777677677777777666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007777767677777776777776700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000777767677777777777767700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000006677777767777776000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000066666606666667000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
ddddddddddddddddddddddfddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddfdddddddddddddfddddfddddfdddfdddddddfddfddffddffddddddfddddddfddddddddddddddddddffffdddddddddddddfddddddddd
ffdddfddddddffdfffdddddddffdfddddddddfdddfdddddddddddfdfdfffddddddddddddddddddfddddddddfddfddddddddddddddddddddddddfddffffddffdf
fddfddddddddfddfdddfddddddddddddfdfdddddddfdfdddddddddddfdfddfdddddddddddddddfdddfddffddffdddfdddfddddddddffdfddffdddddddddddddd
ddddddfdfddfdddddfdfffddddffdddffddddfddddddddffdfdddddfdddddddddddddddfddddddddfdddfdfdddfddddfdfdddfdfdfdfdfdddddddfdddddddddd
dddffddfdfdddddddddfdfdddddddddddddddddddddddddddddddfdfdddddfdfdfddddddfdddfdfddfdddddddddddddfddddfddddddffdddfdfddddddddddddd
ddddddddddddddddddffddfdfddffddddddddddddddddddfdddddddfdddddddddddddddfdfdffdfdfdfdddddddddfdfdfdddddfffffddddddddddddddddddddd
dddfddddfdffdddfdddfffdffdddddddddddddddddddddddfdfddddddddddddfddfdfdfddddffddfddfddddfdddddfdddfddddddddddddddddddddddddddfffd
dddddddfdfddfddffddddfddddfdfdfddfdddddddddfdddddddfddfdddddddfdfdddddddddddfdfddddfdfddddddddddddfddffdfdfdddddddddddffdfddfdfd
dddddddddddddddddddddddddfdddddfdfdfdddddddfddfddddddfdfdfddddfddddddfdfdddfddddfdfdddddddddffddddddddfddfdddddfdffddfdfdddfdddd
fddddddddffddffdddfdfdfddfdfdfdddddddddddffddfffdddffdddffdddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd

__gff__
0001010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000002400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00010000060100602005020050200502006030060300704008040090500c0500d05011050160501e05026050290503a0003f0001c70017700167001670018700197001a7001a7001a70019700177001470012700
011001001d0501d050000001f0500000021050000001f0501f050000001d0502405021050000001f0501d05021050210001d0501f0501f050210501f0501d0501d0001d000000000000000000000000000000000
011000000f0531255314553000000f0531255314553000000f0531255314553000000f0531255314553000000f053125531455300000000000000000000000000000000000000000000000000000000000000000
011000000000000000000001b0531b0530000003055030550000000000000001b0531b0530000003055030550000000000000001b0531b0530000003055030550000000000000001b0531b053000000305503055
011000000000020055220550805500000060550805500000000002005522055080550000006055080550000000000200552205508055000000605508055000000000020055220550805500000060550805500000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000060700000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 01024344
01 02424344
01 02034344
02 01030444
00 41424344
00 41424344
00 06424344

