-- GOLF SOLITAIRE

MARGIN = 40
CARD_DIMENSIONS = { x = 162, y = 204 }
CARD_GAP = { x = 30, y = 40 }

CARD_SPRITE_DIMENSIONS = { x = 27, y = 34 }

SUIT_EXPANSIONS = { C = "Clubs", S = "Spades", H = "Hearts", D = "Diamonds" }

MAX_SCALE = 1

Scale = 1

CardSpriteScale = {
	x = CARD_DIMENSIONS.x / CARD_SPRITE_DIMENSIONS.x * Scale,
	y = CARD_DIMENSIONS.y / CARD_SPRITE_DIMENSIONS.y * Scale,
}

function math.Clamp(val, lower, upper)
	assert(val and lower and upper, "not very useful error message here")
	if lower > upper then
		lower, upper = upper, lower
	end -- swap if boundaries supplied the wrong way
	return math.max(lower, math.min(upper, val))
end

function Shuffle(tbl)
	math.randomseed(os.time())
	for i = #tbl, 2, -1 do
		local j = math.random(i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
end

function GenrateDeck()
	local deck = {}

	local suits = { "C", "S", "H", "D" }

	for _, suit in ipairs(suits) do
		for i = 1, 13 do
			local card = suit .. i
			table.insert(deck, card)
		end
	end

	Shuffle(deck)
	return deck
end

function DistributeDeck(deck)
	local tableu = {}
	for i = 1, 7 do
		table.insert(tableu, {})
	end

	for i = 1, 5 do
		for j = 1, 7 do
			table.insert(tableu[j], table.remove(deck))
		end
	end
	return tableu
end

function love.load()
	Font = love.graphics.newFont(16)
	love.graphics.setDefaultFilter("nearest", "nearest")

	Deck = GenrateDeck()
	Tableu = DistributeDeck(Deck)
	Foundation = { table.remove(Deck) }

	SetupDrawPositions()
	TopCardsPosition = GetTopCardsPosition()
end

function love.update()
	lastMouseState = currentMouseState
	currentMouseState = love.mouse.isDown(1)
	if lastMouseState and not currentMouseState then
		local mx, my = love.mouse.getPosition()
		Click(mx, my)
	end
end

function Click(x, y)
	for i, posn in ipairs(TopCardsPosition) do
		if
			x > posn.x
			and y > posn.y
			and x < posn.x + (CARD_DIMENSIONS.x * Scale)
			and y < posn.y + (CARD_DIMENSIONS.y * Scale)
		then
			print("clicking at " .. i)
			if i == 8 then
				DrawFromStock()
			else
				TryColumn(i)
			end
		end
	end
end

function DrawFromStock()
	if #Deck == 0 then
		return
	end
	table.insert(Foundation, table.remove(Deck))
end

function TryColumn(columnNo) end

function GetTopCardsPosition()
	local topCardsPosition = {}
	for i = 1, 7 do
		table.insert(topCardsPosition, DrawPositions[i][#Tableu[i]])
	end
	table.insert(topCardsPosition, DrawPositions["Stock"])
	return topCardsPosition
end

function love.draw()
	DrawTableu(Tableu)
	DrawBottom(Foundation)
end

function love.resize()
	CardSpriteScale = {
		x = CARD_DIMENSIONS.x / CARD_SPRITE_DIMENSIONS.x * Scale,
		y = CARD_DIMENSIONS.y / CARD_SPRITE_DIMENSIONS.y * Scale,
	}
	SetupDrawPositions()
	TopCardsPosition = GetTopCardsPosition()
end

function SetupDrawPositions()
	Ww, Wh = love.graphics.getDimensions()

	local abs_width = (2 * MARGIN) + (7 * CARD_DIMENSIONS.x) + (6 * CARD_GAP.x)
	local abs_height = (2 * MARGIN) + (4 * CARD_GAP.y) + CARD_DIMENSIONS.y + MARGIN + CARD_DIMENSIONS.y

	Scale = math.Clamp(math.min(Ww / abs_width, Wh / abs_height), 0, MAX_SCALE)

	DrawPositions = {}
	for i = 1, 7 do
		table.insert(DrawPositions, {})
	end

	for i = 1, 5 do
		for j = 1, 7 do
			local posn = {}
			posn.x = (MARGIN + ((j - 1) * (CARD_DIMENSIONS.x + CARD_GAP.x))) * Scale
			posn.y = (MARGIN + ((i - 1) * CARD_GAP.y)) * Scale
			table.insert(DrawPositions[j], posn)
		end
	end

	DrawPositions.Stock = { x = MARGIN * Scale, y = Wh - ((CARD_DIMENSIONS.y + MARGIN) * Scale) }
	DrawPositions.Foundation =
		{ x = (MARGIN + CARD_DIMENSIONS.x + CARD_GAP.x) * Scale, y = Wh - ((CARD_DIMENSIONS.y + MARGIN) * Scale) }
end

function DrawCard(x, y, card)
	local path = "Sprites/" .. SUIT_EXPANSIONS[card:sub(1, 1)] .. "/" .. card .. ".png"
	local cardSprite = love.graphics.newImage(path)
	love.graphics.push()
	love.graphics.scale(CardSpriteScale.x, CardSpriteScale.y)
	love.graphics.draw(cardSprite, x / CardSpriteScale.x, y / CardSpriteScale.y)
	love.graphics.pop()
end

function DrawTableu(tableu)
	for i = 1, 5 do
		for j = 1, 7 do
			local card = tableu[j][i]
			local posn = DrawPositions[j][i]
			DrawCard(posn.x, posn.y, card)
		end
	end
end

function DrawBottom(foundation)
	-- Stock
	local StockPath = #Deck ~= 0 and "Sprites/Backs/back_0.png" or "Sprites/Backs/back_x.png"
	local cardBackSprite = love.graphics.newImage(StockPath)
	love.graphics.push()
	love.graphics.scale(CardSpriteScale.x, CardSpriteScale.y)
	love.graphics.draw(
		cardBackSprite,
		DrawPositions.Stock.x / CardSpriteScale.x,
		DrawPositions.Stock.y / CardSpriteScale.y
	)
	love.graphics.pop()

	-- Foundation
	local y = DrawPositions.Foundation.y
	for i, card in ipairs(Foundation) do
		local x = DrawPositions.Foundation.x + ((i - 1) * CARD_GAP.x)
		DrawCard(x, y, card)
	end
end
