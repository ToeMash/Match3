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
 
    for i = 0, NUM_ROWS - 1 do
        for j = 0, NUM_COLS - 1 do
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


function refillBoard()
    -- Fill the board with new candies if there are any empty spaces in a cascading manner
    local delay = .02
    for i = NUM_ROWS - 1, 0, -1 do
        for j = 0, NUM_COLS - 1 do
            local candy = board[i][j]
            if candy == nil then
                local fall_height = 1

                while i - fall_height >= 0 and board[i - fall_height][j] == nil do
                    fall_height = fall_height + 1
                end

                if i - fall_height > 0 then
                    board[i][j] = board[i - fall_height][j]
                    board[i - fall_height][j] = nil
                    updatePositions()
                else
                    board[i][j] = createCandy(i, j)
                end
                love.timer.sleep(delay)
            end
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

        local candy = board[row][col]

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

        local candy = board[row][col]

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
    for i = 0, NUM_ROWS - 1 do
        board[i] = {}
        for j = 0, NUM_COLS - 1 do
            board[i][j] = createCandy(i, j)
        end
    end

    return board
end

function updatePositions()
    -- Helper function that ensures all candy object positional values match board position
    for i = 0, NUM_ROWS - 1 do
        for j = 0, NUM_COLS - 1 do
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
        for i = 0, NUM_ROWS - 1 do
            for j = 0, NUM_COLS - 1 do
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
                    love.graphics.rectangle("fill", (j - 1) * 64, (i - 1) * 64, 60, 60)
                else
                    color = {0, 0, 0, 255}
                    love.graphics.setColor(color)
                    love.graphics.rectangle("fill", (j - 1) * 64, (i - 1) * 64, 60, 60)
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

function love.update(dt)
    local matches = findMatches()
    removeMatches(matches)
    refillBoard()
    updateScore(matches, mult)
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