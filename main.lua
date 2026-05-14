-- GOLF SOLITAIRE

MARGIN = 40
CARD_DIMENSIONS = { x = 162, y = 204 }
CARD_GAP = { x = 30, y = 40 }

CARD_SPRITE_DIMENSIONS = { x = 27, y = 34 }

MAX_SCALE = 1
BG_SCALE = 4

Scale = 1

CardSpriteScale = {
	x = CARD_DIMENSIONS.x / CARD_SPRITE_DIMENSIONS.x * Scale,
	y = CARD_DIMENSIONS.y / CARD_SPRITE_DIMENSIONS.y * Scale,
}

function math.Clamp(val, lower, upper)
	if lower > upper then
		lower, upper = upper, lower
	end
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
	CardSprites = {}

	local suits = { C = "Clubs", S = "Spades", H = "Hearts", D = "Diamonds" }
	for abbr, name in pairs(suits) do
		for i = 1, 13 do
			local card = abbr .. i
			CardSprites[card] = love.graphics.newImage("Sprites/" .. name .. "/" .. card .. ".png")
		end
	end
	CardSprites.back0 = love.graphics.newImage("Sprites/Backs/back_0.png")
	CardSprites.backX = love.graphics.newImage("Sprites/Backs/back_x.png")
	CardSprites.undo = love.graphics.newImage("Sprites/undo.png")

	Deck = GenrateDeck()
	Tableu = DistributeDeck(Deck)
	Foundation = { table.remove(Deck) }
	Timeline = {}

	SetupDrawPositions()
	TopCardsPosition = GetTopCardsPosition()

	CardSprites.background = love.graphics.newImage("Sprites/table.png")
	CardSprites.background:setWrap("repeat", "repeat")
	BackgroundQuad = love.graphics.newQuad(0, 0, Ww / BG_SCALE, Wh / BG_SCALE, CardSprites.background:getDimensions())
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
		if not posn.x then
			goto continue
		end
		if
			x > posn.x
			and y > posn.y
			and x < posn.x + (CARD_DIMENSIONS.x * Scale)
			and y < posn.y + (CARD_DIMENSIONS.y * Scale)
		then
			if i == 8 then
				DrawFromStock()
			elseif i == 9 then
				Undo()
			else
				TryCard(i)
			end
		end
		::continue::
	end
end

function Undo()
	if #Timeline == 0 then
		return
	end
	local toMoveto = table.remove(Timeline)
	if toMoveto == 0 then
		table.insert(Deck, table.remove(Foundation))
	else
		table.insert(Tableu[toMoveto], table.remove(Foundation))
	end
end

function DrawFromStock()
	if #Deck == 0 then
		return
	end
	table.insert(Foundation, table.remove(Deck))
	table.insert(Timeline, 0)
end

function TryCard(columnNo)
	local card = Tableu[columnNo][#Tableu[columnNo]]
	if not card then
		return
	end
	local cardValue = tonumber(card:sub(2, 3))
	local topFoundationCardValue = tonumber(Foundation[#Foundation]:sub(2, 3))
	if math.abs(topFoundationCardValue - cardValue) == 1 then
		table.insert(Foundation, table.remove(Tableu[columnNo]))
		TopCardsPosition = GetTopCardsPosition()
		table.insert(Timeline, columnNo)
	end
end

function GetTopCardsPosition()
	local topCardsPosition = {}
	for i = 1, 7 do
		if #Tableu[i] == 0 then
			table.insert(topCardsPosition, {})
			goto continue
		end
		table.insert(topCardsPosition, DrawPositions[i][#Tableu[i]])
		::continue::
	end
	table.insert(topCardsPosition, DrawPositions["Stock"])
	table.insert(topCardsPosition, DrawPositions["Undo"])
	return topCardsPosition
end

function love.draw()
	love.graphics.draw(CardSprites.background, BackgroundQuad, 0, 0, 0, BG_SCALE, BG_SCALE)
	DrawTableu()
	DrawBottom()
end

function love.resize()
	CardSpriteScale = {
		x = CARD_DIMENSIONS.x / CARD_SPRITE_DIMENSIONS.x * Scale,
		y = CARD_DIMENSIONS.y / CARD_SPRITE_DIMENSIONS.y * Scale,
	}
	SetupDrawPositions()
	TopCardsPosition = GetTopCardsPosition()
	BackgroundQuad = love.graphics.newQuad(0, 0, Ww / BG_SCALE, Wh / BG_SCALE, CardSprites.background:getDimensions())
end

function SetupDrawPositions()
	Ww, Wh = love.graphics.getDimensions()

	local abs_width = (2 * MARGIN) + (7 * CARD_DIMENSIONS.x) + (6 * CARD_GAP.x)
	local abs_height = (2 * MARGIN)
		+ (4 * CARD_GAP.y)
		+ CARD_DIMENSIONS.y
		+ MARGIN
		+ CARD_DIMENSIONS.y
		+ MARGIN
		+ CARD_DIMENSIONS.y

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
	DrawPositions.Undo = { x = MARGIN * Scale, y = Wh - 2 * ((CARD_DIMENSIONS.y + MARGIN) * Scale) }
	DrawPositions.Foundation =
		{ x = (MARGIN + CARD_DIMENSIONS.x + CARD_GAP.x) * Scale, y = Wh - ((CARD_DIMENSIONS.y + MARGIN) * Scale) }
end

function DrawCard(x, y, card)
	if not card then
		return
	end
	local sprite = CardSprites[card]
	love.graphics.push()
	love.graphics.scale(CardSpriteScale.x, CardSpriteScale.y)
	love.graphics.draw(sprite, x / CardSpriteScale.x, y / CardSpriteScale.y)
	love.graphics.pop()
end

function DrawTableu()
	for i = 1, 5 do
		for j = 1, 7 do
			local card = Tableu[j][i]
			local posn = DrawPositions[j][i]
			DrawCard(posn.x, posn.y, card)
		end
	end
end

function DrawBottom()
	-- Stock
	local cardBackSprite = #Deck ~= 0 and CardSprites.back0 or CardSprites.backX
	love.graphics.push()
	love.graphics.scale(CardSpriteScale.x, CardSpriteScale.y)
	love.graphics.draw(
		cardBackSprite,
		DrawPositions.Stock.x / CardSpriteScale.x,
		DrawPositions.Stock.y / CardSpriteScale.y
	)
	love.graphics.pop()

	-- Undo
	local cardBackSprite = CardSprites.undo
	love.graphics.push()
	love.graphics.scale(CardSpriteScale.x, CardSpriteScale.y)
	love.graphics.draw(
		cardBackSprite,
		DrawPositions.Undo.x / CardSpriteScale.x,
		DrawPositions.Undo.y / CardSpriteScale.y
	)
	love.graphics.pop()

	-- Foundation
	local y = DrawPositions.Foundation.y
	for i, card in ipairs(Foundation) do
		local x = DrawPositions.Foundation.x + ((i - 1) * CARD_GAP.x * Scale)
		DrawCard(x, y, card)
	end
end
