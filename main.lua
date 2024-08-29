local game = {}

-- Constants for candy types
local CANDY_TYPES = {
    ["red"] = 1,
    ["yellow"] = 2,
    ["green"] = 3,
    ["blue"] = 4,
    ["purple"] = 5,
}

local NUM_ROWS = 6
local NUM_COLS = 7

local score = 0
local total_moves = 10
local moves_left = total_moves
local mult = 1
local win = false
local win_cond = 100

timer = {}
timer[0] = 0

board = {}

-- two variables to track selected candies
selected_candy1 = nil
selected_candy2 = nil

function createCandy(i, j, t)
    -- Create a new candy with optional type t
    local keys = {}
    for k in pairs(CANDY_TYPES) do
        table.insert(keys, k)
    end
    local randomIndex = math.random(1, #keys)
    local type_t = t or keys[randomIndex]
    return { type = type_t, x = i, y = j }
end

function areAdjacent(c1, c2)
    -- Check if two candies are adjacent
    if c1 and c2 then
        if math.abs(c1.x - c2.x) == 1 and math.abs(c1.y - c2.y) == 0 then
            return true
        end
        if math.abs(c1.x - c2.x) == 0 and math.abs(c1.y - c2.y) == 1 then
            return true
        end
        return false
    end
    return false
end

function isMatch(c1, c2)
    -- Check if two candies are matching in type
    return c1 and c2 and c1.type == c2.type 
end

function getNeighbors(candy)
    -- Helper function which returns a list of all adjacent candies of input candy
    local neighbors = {}
    local neighbor = nil
    if candy == nil then
        return neighbors
    end
    if candy.x < NUM_COLS - 2 then
        neighbor = board[candy.x + 1][candy.y]
        table.insert(neighbors, neighbor)
    end
    if candy.x ~= 0 then
        neighbor = board[candy.x - 1][candy.y]
        table.insert(neighbors, neighbor)
    end
    if candy.y < NUM_ROWS - 2 then
        neighbor = board[candy.x][candy.y + 1]
        table.insert(neighbors, neighbor)
    end
    if candy.y ~= 0 then
        neighbor = board[candy.x][candy.y - 1]
        table.insert(neighbors, neighbor)
    end

    return neighbors
end

function getMatchingNeighbors(candy)
    -- Returns a list of matching neighbors of input candy
    local neighbors = getNeighbors(candy)
    local matched_neighbors = {}
    for _, neighbor in ipairs(neighbors) do
        if isMatch(candy, neighbor) then
            table.insert(matched_neighbors, neighbor)
        end
    end
    
    return matched_neighbors
end

function hasVal(val, arr)
    -- Helper function to check if an array contains a value
    for _, item in ipairs(arr) do
        if item == val then
            return true
        end
    end

    return false
end

function findMatches()
    -- Function to locate all existing matches on the board
    local matches = {}
 
    for i = 0, NUM_COLS - 1 do
        for j = 0, NUM_ROWS - 1 do
            local visited = {}
            local candy = board[i][j]
            if candy and not visited[candy] then
                local matched_neighbors = findConnectedMatches(candy, visited)
                if #matched_neighbors >= 3 then
                    table.insert(matches, matched_neighbors)
                end
            end
        end
    end
    return matches
end

function findConnectedMatches(candy, visited)
    -- Helper function for findMatches() which returns a list of neighbors of the input candy that match
    local matched_neighbors = {}
    table.insert(matched_neighbors, candy)
    visited[candy] = true

    local queue = {}
    table.insert(queue, candy)

    while #queue > 0 do
        local current = table.remove(queue, 1)
        for _, neighbor in ipairs(getNeighbors(current)) do
            if neighbor and neighbor.type == candy.type and not visited[neighbor] then
                table.insert(matched_neighbors, neighbor)
                visited[neighbor] = true
                table.insert(queue, neighbor) 
            end
        end
    end
    return matched_neighbors
end

function removeMatches(matches)
    -- Remove candies from the board based on the given matches
    for _, matched_set in ipairs(matches) do
        for _, candy in ipairs(matched_set) do
            board[candy.x][candy.y] = nil
        end
    end
end

function love.mousepressed(x, y, button, istouch)
    -- Convert mouse coordinates to board indices
    if button == 1 then
        local col = math.floor(x / 64) + 1
        local row = math.floor(y / 64) + 1
        printx = x
        printy = y
        printcol = col
        printrow = row

        local candy = board[col][row]

        if candy then
            selected_candy1 = candy
        else
            selected_candy1 = nil
            selected_candy2 = nil
        end
    end
end

function love.mousereleased(x, y, button)
    if button == 1 then
        local col = math.floor(x / 64) + 1
        local row = math.floor(y / 64) + 1

        local candy = board[col][row]

        if candy then
            selected_candy2 = candy
        else
            selected_candy2 = nil
            selected_candy1 = nil
        end
    end
end

function setupBoard()
    -- Initialize the board with random candies
    local board = {}
    for i = 0, NUM_COLS - 1 do
        board[i] = {}
        for j = 0, NUM_ROWS - 1 do
            board[i][j] = createCandy(i, j)
        end
    end

    return board
end

function updatePositions()
    -- Helper function that ensures all candy object positional values match board position
    for i = 0, NUM_COLS - 1 do
        for j = 0, NUM_ROWS - 1 do
            local candy = board[i][j]
            if candy ~= nil then
                candy.x = i
                candy.y = j
            end
        end
    end
end

function swapCandy(c1, c2)
    -- Swaps the location of two candies
    temp = board[c1.x][c1.y]
    board[c1.x][c1.y] = board[c2.x][c2.y]
    board[c2.x][c2.y] = temp
    selected_candy1 = nil
    selected_candy2 = nil
end

function love.load()
    board = setupBoard()
    printx = 0
    printy = 0
    printcol = 0
    printrow = 0
    
    score = 0
    moves_left = 10

    --vars used for debugging purposes
    last_pressed1 = nil
    last_pressed2 = nil
end

function love.draw()
    love.graphics.setBackgroundColor(200, 200, 200)
    if not win then
        for i = 0, NUM_COLS - 1 do
            for j = 0, NUM_ROWS - 1 do
                local candy = board[i][j]
                if candy then
                    local color = { 255, 0, 0, 255 }  -- Default to red color
                    if candy.type == "yellow" then
                        color = { 255, 255, 0, 255 }
                    elseif candy.type == "green" then
                        color = { 0, 255, 0, 255 }
                    elseif candy.type == "blue" then
                        color = { 0, 0, 255, 255 }
                    elseif candy.type == "purple" then
                        color = { 255, 0, 255, 255 }
                    end

                    love.graphics.setColor(color)
                    love.graphics.rectangle("fill", (i - 1) * 64, (j - 1) * 64, 60, 60)
                else
                    color = {0, 0, 0, 255}
                    love.graphics.setColor(color)
                    love.graphics.rectangle("fill", (i - 1) * 64, (j - 1) * 64, 60, 60)
                end
            end
        end
        love.graphics.setColor(0, 0, 0, 255)
        --if last_pressed1 == nil or last_pressed2 == nil then
        --    love.graphics.print(string.format("%s,%s", last_pressed1, last_pressed2), printx, printy)
        --else
        --    love.graphics.print(string.format("%s,%s", last_pressed1.type, last_pressed2.type), printx, printy)
        --end

        love.graphics.setColor(0, 0, 0, 255)  -- Use a different color for scores maybe
        love.graphics.print("Score: " .. score, 400, 10)
        love.graphics.print("Moves Left: " .. moves_left, 400, 30)
        love.graphics.print("Multiplier: " .. mult, 400, 50)
    
    else
        love.graphics.print("YOU WON!: ", 10, 50)
    end
end

function updateScore(matches)
    -- Updates the score based on input matches and current mult value
    if #matches > 0 then
        score = score + mult * #matches
        mult = mult + .1
    end
end

function checkRow(row)
    -- Check a passed in row for nil cells and return them as an array
    local nil_cells = {}
    for i = NUM_COLS - 1, 0, -1 do
        local candy = board[i][row]
        if candy == nil then
            local cell = {x = i, y = row}
            table.insert(nil_cells, cell)
        end
    end

    return nil_cells
end

function findCandyToFall(cell)
    -- Determines which candy will fall into the passed in cell, if none, create a new candy
    local i = cell["x"]
    local j = cell["y"]
    local fall_height = 1
    local cell_pair = {destination = cell, source = nil}
    while j - fall_height > 0 and board[i][j - fall_height] == nil do
        fall_height = fall_height + 1
    end

    local candy_to_fall = nil
    if j - fall_height > 0 then
        candy_to_fall = board[i][j - fall_height]
    else
        board[i][0] = createCandy(i, 0)
        candy_to_fall = board[i][0]
    end
    updatePositions()
    cell_pair["source"] = candy_to_fall
    return cell_pair
end

function refillBoard()
    -- searches for empty cells and refills them
    if timer[0] > .1 then
        for row = NUM_ROWS - 1, 0, -1 do
            local nil_cells = checkRow(row)
            local cells_to_fall = {}
            for _, cell in ipairs(nil_cells) do
                table.insert(cells_to_fall, findCandyToFall(cell))
            end
            cells_to_fall = cascade(cells_to_fall)
            nil_cells = checkRow(row)

            if #nil_cells > 0 then
                row = row + 1
            end
        end

        timer[0] = 0
    end
end

function slowDescent(cell_pair)
    -- Helper function which causes a candy to descend 1 space at a time, returns 0 if the candy is already at the bottom, 1 otherwise
    local x = cell_pair["destination"]["x"]
    local dest_y = cell_pair["destination"]["y"]
    local src_y = cell_pair["source"]["y"]
    if src_y + 1 >= NUM_ROWS - 1 or src_y < dest_y then
        board[x][src_y + 1] = cell_pair["source"]
        board[x][src_y] = nil
        updatePositions()
        return 1
    end
    return 0
end

function cascade(cells_to_fall)
    -- Takes an array of cell_pairs which contain dst and src cells and moves each src cell closer to its dst by 1
    local indices_to_remove = {}
    for i, cell_pair in ipairs(cells_to_fall) do
        if slowDescent(cell_pair) == 1 then
            cell_pair["source"] = {x = cell_pair["source"]["x"], y = cell_pair["source"]["y"] + 1}
            cells_to_fall[i] = cell_pair -- may be unnecessary?
        else
            table.insert(indices_to_remove, 0, i)
        end
    end

    for _, index in ipairs(indices_to_remove) do
        table.remove(cells_to_fall, index)
    end
    return cells_to_fall
end

function love.conf(t)
	t.console = true
end

function checkForAction()
    -- Checks to see if 2 valid candies are selected by the player, and updates board
    if selected_candy1 and selected_candy2 and areAdjacent(selected_candy1, selected_candy2) and moves_left > 0 then
        swapCandy(selected_candy1, selected_candy2)
        updatePositions()

        local matches = findMatches()
        mult = 1
        removeMatches(matches)
        refillBoard()
        updateScore(matches)

        moves_left = moves_left - 1
        
    end
end

function love.update(dt)
    timer[0] = timer[0] + dt
    local matches = findMatches()
    removeMatches(matches)
    refillBoard()
    updateScore(matches, mult)

    checkForAction()
    
    if win then
        love.timer.sleep(3)
        love.event.quit("restart")
    end
    if moves_left == 0 then
        if score > win_cond then
            win = true
        end
    end
end