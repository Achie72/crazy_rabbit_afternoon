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
 step_overflow_2 = 0
}

pressed_button = 0
lost = 0

wolves={}

player={
  x = -1,
  y = -1,
  placed = 0
}

function _init()
  lost = 0
  wolves = {}
  player.x = -1
  player.y = -1
  player.placed = 0
  global.carrot_left = 0
  cls()

  for x=0,global.mapsize-1 do
    for y=0,global.mapsize-2 do
      mset(x,y,1)
    end
  end
  dig(0,0,0.5,400)
  dig(8,8,0.5,400)
  dig(4,4,0.5,100)
  place_rabbit_holes(0.05)
  place_carrots(0.03)

  for x=0,global.mapsize-1 do
    for y=0,global.mapsize-2 do
      if mget(x,y) == 4 then
        global.carrot_left += 1
      end
    end
  end
  place_wolves(0.03)
  place_player()
end

function place_rabbit_holes(probability)
  for x=0,global.mapsize-1 do
    for y=0,global.mapsize-2 do
      rng = rnd(1)
      if (rng <= probability) and (mget(x,y) == 2) then
        mset(x,y,3)
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
        if (rng <= probability) and (mget(x,y) == 2) then
          mset(x,y,4)
          carrot_number += 1
        end
      end
    end
  end
end

function place_wolves(probability)
  
  while #wolves <= flr(flr(global.current_level/5) + global.difficulty) do
    x_rand = flr(rnd(15)) + 1
    y_rand = flr(rnd(14)) + 1
    if not ((x_rand < 0) or (x_rand > 15) or (y_rand < 0) or (y_rand > 14)) then
      rng = rnd(1)
      if (rng <= probability) and (mget(x_rand,y_rand) == 2) then
        local wolf = {
          x = x_rand,
          y = y_rand,
          spr = 32
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
      if (mget(x_rand,y_rand) == 3) then
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
    mset(x,y,2)
    outside = true
  end
end


function check_carrot()
  if (mget(player.x,player.y) == 4) then
    sfx(0)
    mset(player.x,player.y,2)
    global.score +=1
    global.carrot_left -= 1
  end
end

function line_of_sight(x0,y0,x1,y1)

  if(mget(x0,y0) == 3) then
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

  if (mget(x0, y0) == 1) then return false end

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
    if (mget(x0, y0) == 1) then return false end
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
          if not (mget(wolf.x+step_x,wolf.y+step_y) == 1) then
           outside = false
          end
          end
        end
      wolf.x += step_x
      wolf.y += step_y
    end
    if (player.x == wolf.x) and (player.y == wolf.y) then
      printh("on it")
      if not (mget(player.x,player.y) == 3) then
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

function calculate_difficulty()
  global.difficulty = 1 + (global.steps/100) + (global.step_overflow_1*100) + (global.step_overflow_2*1000)
  printh(global.difficulty)
  printh(flr(flr(global.current_level/5) + global.difficulty))
end


function _update()
  --printh("lost: "..lost.." state: "..global.state)
  if global.state == 0 then
    if btnp(4) then
      global.state = 1
      _init()
    end
  else 
    if not (lost == 1) then

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
        if btnp(4) then
          --_init()
          --global.current_level +=1
        end
        if btnp(5) then
          pressed_button +=1
          global.steps +=1
        end
        
        if btnp(0) then
          new_x = player.x - 1
          pressed_button +=1
          global.steps +=1
        end
        if btnp(1) then
          new_x = player.x + 1
          pressed_button +=1
          global.steps +=1
        end
        if btnp(2) then
          new_y = player.y - 1
          pressed_button +=1
          global.steps +=1
        end
        if btnp(3) then
          new_y = player.y + 1
          pressed_button +=1
          global.steps +=1
        end

      -- move player if valid movement
      if (not (mget(new_x,new_y) == 1)) then
        if not ((new_x < 0) or (new_x > 15) or (new_y < 0) or (new_y > 14)) then
          player.x = new_x
          player.y = new_y
        end
      end

     for wolf in all(wolves) do
        if (player.x == wolf.x) and (player.y == wolf.y) then
          if not (mget(player.x,player.y) == 3) then    
            lost = 1
          end
        end
      end



      -- move enemies if player did 2 steps
      while pressed_button == 2 do
        move_wolves()
        pressed_button = 0
      end

      check_carrot()

      if(global.carrot_left == 0) then
      global.current_level += 1
        _init()
      end

      for wolf in all(wolves) do
        wolf_sight(wolf)
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
    rectfill(32,60,96,81,7)
    rectfill(33,61,95,80,0)
    print("you got eaten!",38,64,8)

    if(time()%2 < 1) then
      print("- \142 -",55,72,8)
    end

  else
    cls()
    if global.state == 0 then
      draw_menu()
    else
      map()
      for wolf in all(wolves) do
        spr(63,wolf.x*8,wolf.y*8)
        spr(wolf.spr,wolf.x*8,wolf.y*8)
      end
      if(mget(player.x,player.y) == 3) then
        spr(17,player.x*8,player.y*8)
        --printh("on")
        --printh(player.x.." "..player.y)
        --printh(mget(player.x,player.y))
      else
        spr(16,player.x*8,player.y*8)
        --printh("off")
        --printh(player.x.." "..player.y)
      end
      --print(global.score)
      for paw in all(paws) do
        spr(paw.spr,paw.x,paw.y)
      end
      draw_ui()

    end
  end
end

function draw_ui()
  print("ate: "..global.score,0,120,9)
  print("|",38,120,7)
  print("lvl: "..global.current_level,42,120,9)
  print("|",72,120,7)
  print("left: "..global.carrot_left,76,120,9)
  print("| "..pressed_button,110,120,7)
  --print("step: "..pressed_button,96,120,9)
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
00000000000003030000005000000000000bb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000030000000000000000000b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000030303330500000000055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000300400000400000500500009900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700033300400000000000500500000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000004000000000000005055050000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0077077000dd0dd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070000d00d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070000d00d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0077770000dddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070700000d0d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0077070000dd0d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0077770000dddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00220220008808800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020200000808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00202020008080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00222220008888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020200000808000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00002000000080000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00080800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
08000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00088800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00088800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00007777677677777777666777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00007777767677777776777776700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000777767677777777777767700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000006677777777777776000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000066777777777767000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
0001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000060700000000010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 41424344
00 06424344

