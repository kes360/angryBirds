--[[
    GD50
    Angry Birds

    Original Author: Colton Ogden
    cogden@cs50.harvard.edu
    Modified and Extended by Kevin Sinusas
    kes360@g.harvard.edu

]]

Level = Class{}

function Level:init()
    
    -- create a new "world" (where physics take place), with no x gravity
    -- and 30 units of Y gravity (for downward force)
    self.world = love.physics.newWorld(0, 300)

    -- bodies we will destroy after the world update cycle; destroying these in the
    -- actual collision callbacks can cause stack overflow and other errors
    self.destroyedBodies = {}

    -- define collision callbacks for our world; the World object expects four,
    -- one for different stages of any given collision
    function beginContact(a, b, coll)

        local types = {}
        types[a:getUserData()] = true
        types[b:getUserData()] = true

        -- moved handing of collisions with player inside this condition to only check once that a player's involved, then check for other half of collision inside
        if types['Player'] then

            -- set the player's category to be the unsplittable value to prevent post-collision splitting (no matter what the player collided with)
            local playerFixture = a:getUserData() == 'Player' and a or b
            playerFixture:setCategory(UNSPLITTABLE)

             -- if the player collided with an obstacle...
            if types['Obstacle'] then

                -- grab the body that belongs to the player
                local obstacleFixture = a:getUserData() == 'Obstacle' and a or b
                
                -- destroy the obstacle if player's combined X/Y velocity is high enough
                local velX, velY = playerFixture:getBody():getLinearVelocity()
                local sumVel = math.abs(velX) + math.abs(velY)

                if sumVel > 20 then
                    table.insert(self.destroyedBodies, obstacleFixture:getBody())
                end
            end

            -- if the player collided with an enemy alien...
            if types['Alien'] then

                -- grab the bodies that belong to the player and alien
                local alienFixture = a:getUserData() == 'Alien' and a or b

                -- destroy the alien if player is traveling fast enough
                local velX, velY = playerFixture:getBody():getLinearVelocity()
                local sumVel = math.abs(velX) + math.abs(velY)

                if sumVel > 20 then
                    table.insert(self.destroyedBodies, alienFixture:getBody())
                end
            end

            -- if player hit the ground, play a bounce sound
            if types['Ground'] then
                gSounds['bounce']:stop()
                gSounds['bounce']:play()
            end
        end

        -- if there was a collision between an obstacle and an alien, as by debris falling...
        if types['Obstacle'] and types['Alien'] then

            -- grab the body that belongs to the player
            local obstacleFixture = a:getUserData() == 'Obstacle' and a or b
            local alienFixture = a:getUserData() == 'Alien' and a or b

            -- destroy the alien if falling debris is falling fast enough
            local velX, velY = obstacleFixture:getBody():getLinearVelocity()
            local sumVel = math.abs(velX) + math.abs(velY)

            if sumVel > 20 then
                table.insert(self.destroyedBodies, alienFixture:getBody())
            end
        end

    end

    -- the remaining three functions here are sample definitions, but we are not
    -- implementing any functionality with them in this demo; use-case specific
    -- http://www.iforce2d.net/b2dtut/collision-anatomy
    function endContact(a, b, coll)
        
    end

    function preSolve(a, b, coll)

    end

    function postSolve(a, b, coll, normalImpulse, tangentImpulse)

    end

    -- register just-defined functions as collision callbacks for world
    self.world:setCallbacks(beginContact, endContact, preSolve, postSolve)



    -- aliens in our scene
    self.aliens = {}

    -- shows alien before being launched and its trajectory arrow
    self.launchMarker = AlienLaunchMarker(self.world)

    -- obstacles guarding aliens that we can destroy
    self.obstacles = {}

    -- simple edge shape to represent collision for ground
    self.edgeShape = love.physics.newEdgeShape(0, 0, VIRTUAL_WIDTH * 3, 0)

    -- spawn an alien to try and destroy
    table.insert(self.aliens, Alien(self.world, 'square', VIRTUAL_WIDTH - 80, VIRTUAL_HEIGHT - TILE_SIZE - ALIEN_SIZE / 2, 'Alien'))

    -- spawn a few obstacles
    table.insert(self.obstacles, Obstacle(self.world, 'vertical',
        VIRTUAL_WIDTH - 120, VIRTUAL_HEIGHT - 35 - 110 / 2))
    table.insert(self.obstacles, Obstacle(self.world, 'vertical',
        VIRTUAL_WIDTH - 35, VIRTUAL_HEIGHT - 35 - 110 / 2))
    table.insert(self.obstacles, Obstacle(self.world, 'horizontal',
        VIRTUAL_WIDTH - 80, VIRTUAL_HEIGHT - 35 - 110 - 35 / 2))

    -- ground data
    self.groundBody = love.physics.newBody(self.world, -VIRTUAL_WIDTH, VIRTUAL_HEIGHT - 35, 'static')
    self.groundFixture = love.physics.newFixture(self.groundBody, self.edgeShape)
    self.groundFixture:setFriction(0.5)
    self.groundFixture:setUserData('Ground')

    -- background graphics
    self.background = Background()
end

function Level:update(dt)
    
    -- update launch marker, which shows trajectory
    self.launchMarker:update(dt)

    -- Box2D world update code; resolves collisions and processes callbacks
    self.world:update(dt)

    -- destroy all bodies we calculated to destroy during the update call
    for k, body in pairs(self.destroyedBodies) do
        if not body:isDestroyed() then 
            body:destroy()
        end
    end

    -- reset destroyed bodies to empty table for next update phase
    self.destroyedBodies = {}

    -- remove all destroyed obstacles from level
    for i = #self.obstacles, 1, -1 do
        if self.obstacles[i].body:isDestroyed() then
            table.remove(self.obstacles, i)

            -- play random wood sound effect
            local soundNum = math.random(5)
            gSounds['break' .. tostring(soundNum)]:stop()
            gSounds['break' .. tostring(soundNum)]:play()
        end
    end

    -- remove all destroyed aliens from level 
    for i = #self.aliens, 1, -1 do
        if self.aliens[i].body:isDestroyed() then
            table.remove(self.aliens, i)
            gSounds['kill']:stop()
            gSounds['kill']:play()
        end
    end
    
    -- replace launch marker if original aliens stopped moving after launch
    if self.launchMarker.launched then

        -- reset the done player count to zero for a new check at this moment of number of stopped/off-screen player aliens
        local donePlayers = 0

        -- check all player alien positions and speeds
        for k, alien in pairs(self.launchMarker.playerAliens) do
            local xPos, yPos = alien.body:getPosition()
            local xVel, yVel = alien.body:getLinearVelocity()

            -- add to count of how many player aliens at this moment are stopped moving or off the screen (including off screen to the right)
            if xPos < 0 or xPos > VIRTUAL_WIDTH or (math.abs(xVel) + math.abs(yVel) < 10) then -- raised speed threshold defined as stopped moving
                donePlayers = donePlayers + 1
                -- print('alien ' .. tostring(k) ..' done.')

                -- if all the player aliens are stopped or off screen
                if donePlayers == #self.launchMarker.playerAliens then

                    --mark all player aliens for destruction and respawn
                    for k, donePlayer in pairs(self.launchMarker.playerAliens) do
                        table.insert(self.destroyedBodies, donePlayer.body)
                    end
                    self.launchMarker.playerAliens = {}
                    self.launchMarker = AlienLaunchMarker(self.world)

                    -- re-initialize level if we have no more aliens
                    if #self.aliens == 0 then
                        gStateMachine:change('start')
                    end
                end
        
            end
        end

    end

    
end


function Level:render()
    
    -- render ground tiles across full scrollable width of the screen
    for x = -VIRTUAL_WIDTH, VIRTUAL_WIDTH * 2, 35 do
        love.graphics.draw(gTextures['tiles'], gFrames['tiles'][12], x, VIRTUAL_HEIGHT - 35)
    end

    self.launchMarker:render()

    for k, alien in pairs(self.aliens) do
        alien:render()
    end

    for k, obstacle in pairs(self.obstacles) do
        obstacle:render()
    end

    -- render instruction text if we haven't launched bird
    if not self.launchMarker.launched then
        love.graphics.setFont(gFonts['medium'])
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.printf('Click and drag circular alien to shoot!',
            0, 64, VIRTUAL_WIDTH, 'center')
        love.graphics.setColor(1, 1, 1, 1)
    end

    -- render victory text if all aliens are dead
    if #self.aliens == 0 then
        love.graphics.setFont(gFonts['huge'])
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.printf('VICTORY', 0, VIRTUAL_HEIGHT / 2 - 32, VIRTUAL_WIDTH, 'center')
        love.graphics.setColor(1, 1, 1, 1)
    end
end