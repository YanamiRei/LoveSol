-- GOLF SOLITAIRE

MARGIN = 40
CARD_DIMENSIONS = { x = 162, y = 204 }
CARD_GAP = { x = 30, y = 40 }

CARD_SPRITE_DIMENSIONS = { x = 27, y = 34 }
DIALOG_BOX_SPRITE_DIMENSION = 3

MAX_SCALE = 1
BG_SCALE = 4
BASE_FONT_SIZE = 64

Scale = 1

PixelPerfectScale = CARD_DIMENSIONS.x / CARD_SPRITE_DIMENSIONS.x * Scale

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
	DialogOpen = false
	LoadFont()
	love.graphics.setDefaultFilter("nearest", "nearest")
	Sprites = {}

	local suits = { C = "Clubs", S = "Spades", H = "Hearts", D = "Diamonds" }
	for abbr, name in pairs(suits) do
		for i = 1, 13 do
			local card = abbr .. i
			Sprites[card] = love.graphics.newImage("Sprites/" .. name .. "/" .. card .. ".png")
		end
	end
	Sprites.back0 = love.graphics.newImage("Sprites/Backs/back_0.png")
	Sprites.backX = love.graphics.newImage("Sprites/Backs/back_x.png")
	Sprites.undo = love.graphics.newImage("Sprites/undo.png")
	Sprites.box = {}
	Sprites.box.corner = love.graphics.newImage("Sprites/DialogBox/corner.png")
	Sprites.box.edge = love.graphics.newImage("Sprites/DialogBox/edge.png")
	Sprites.box.center = love.graphics.newImage("Sprites/DialogBox/center.png")
	Sprites.button = {}
	Sprites.button.corner = love.graphics.newImage("Sprites/Button/corner.png")
	Sprites.button.edge = love.graphics.newImage("Sprites/Button/edge.png")
	Sprites.button.center = love.graphics.newImage("Sprites/Button/center.png")
	Sprites.buttonHot = {}
	Sprites.buttonHot.corner = love.graphics.newImage("Sprites/Button/cornerHot.png")
	Sprites.buttonHot.edge = love.graphics.newImage("Sprites/Button/edgeHot.png")
	Sprites.buttonHot.center = love.graphics.newImage("Sprites/Button/centerHot.png")

	Deck = GenrateDeck()
	Tableu = DistributeDeck(Deck)
	Foundation = { table.remove(Deck) }
	Timeline = {}

	SetupDrawPositions()
	TopCardsPosition = GetTopCardsPosition()

	Sprites.background = love.graphics.newImage("Sprites/table.png")
	Sprites.background:setWrap("repeat", "repeat")
	BackgroundQuad = love.graphics.newQuad(0, 0, Ww / BG_SCALE, Wh / BG_SCALE, Sprites.background:getDimensions())
end

function LoadFont()
	Font = love.graphics.newFont("Fonts/PixelSans.ttf", math.Clamp(BASE_FONT_SIZE * Scale, 1, 1000))
	love.graphics.setFont(Font)
end

function love.update()
	lastMouseState = currentMouseState
	currentMouseState = love.mouse.isDown(1)
	if lastMouseState and not currentMouseState and not DialogOpen then
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
	love.graphics.draw(Sprites.background, BackgroundQuad, 0, 0, 0, BG_SCALE, BG_SCALE)
	DrawTableu()
	DrawBottom()
	if DialogOpen then
		DrawDialog("You Lose!", "Play again", function()
			DialogOpen = false
		end)
	end
end

function love.resize()
	SetupDrawPositions()
	PixelPerfectScale = CARD_DIMENSIONS.x / CARD_SPRITE_DIMENSIONS.x * Scale
	TopCardsPosition = GetTopCardsPosition()
	BackgroundQuad = love.graphics.newQuad(0, 0, Ww / BG_SCALE, Wh / BG_SCALE, Sprites.background:getDimensions())
	LoadFont()
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
	local sprite = Sprites[card]
	love.graphics.push()
	love.graphics.scale(PixelPerfectScale, PixelPerfectScale)
	love.graphics.draw(sprite, x / PixelPerfectScale, y / PixelPerfectScale)
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
	local cardBackSprite = #Deck ~= 0 and Sprites.back0 or CardSprites.backX
	love.graphics.push()
	love.graphics.scale(PixelPerfectScale, PixelPerfectScale)
	love.graphics.draw(
		cardBackSprite,
		DrawPositions.Stock.x / PixelPerfectScale,
		DrawPositions.Stock.y / PixelPerfectScale
	)
	love.graphics.pop()

	-- Undo
	local cardBackSprite = Sprites.undo
	love.graphics.push()
	love.graphics.scale(PixelPerfectScale, PixelPerfectScale)
	love.graphics.draw(
		cardBackSprite,
		DrawPositions.Undo.x / PixelPerfectScale,
		DrawPositions.Undo.y / PixelPerfectScale
	)
	love.graphics.pop()

	-- Foundation
	local y = DrawPositions.Foundation.y
	for i, card in ipairs(Foundation) do
		local x = DrawPositions.Foundation.x + ((i - 1) * CARD_GAP.x * Scale)
		DrawCard(x, y, card)
	end
end

function DrawDialog(text, buttonText, onPressed)
	local spriteSize = DIALOG_BOX_SPRITE_DIMENSION * PixelPerfectScale

	local totalHeight = math.max(
		(((2 * MARGIN) + MARGIN + MARGIN + MARGIN + (2 * MARGIN)) * Scale)
			+ Font:getHeight(text)
			+ Font:getHeight(buttonText),
		2 * spriteSize
	)
	local totalWidth = math.max(
		math.max(
			(((2 * MARGIN) + (2 * MARGIN)) * Scale) + Font:getWidth(text),
			(((2 * MARGIN) + MARGIN + MARGIN + (2 * MARGIN)) * Scale) + Font:getWidth(buttonText)
		),
		2 * spriteSize
	)

	local x = ((Ww / 2) - (totalWidth / 2))
	local y = ((Wh / 2) - (totalHeight / 2))

	drawBox(Sprites.box, x, y, totalWidth, totalHeight)

	love.graphics.print(
		{ { 0, 0, 0, 1 }, text },
		x + (totalWidth / 2) - Font:getWidth(text) / 2,
		y + (2 * MARGIN * Scale)
	)

	local buttonX = x + (2 * MARGIN * Scale)
	local buttonY = y + totalHeight - ((MARGIN + (2 * MARGIN)) * Scale) - Font:getHeight(buttonText)

	drawButton(buttonText, buttonX, buttonY, onPressed)
end

function drawBox(spriteSet, baseX, baseY, totalWidth, totalHeight)
	local x = baseX / PixelPerfectScale
	local y = baseY / PixelPerfectScale

	local baseSpriteSize = DIALOG_BOX_SPRITE_DIMENSION
	local spriteSize = baseSpriteSize * PixelPerfectScale

	love.graphics.push()
	love.graphics.scale(PixelPerfectScale, PixelPerfectScale)

	-- Corners
	love.graphics.draw(spriteSet.corner, x, y)
	love.graphics.draw(
		spriteSet.corner,
		x + (baseSpriteSize / 2) + (totalWidth / PixelPerfectScale) - baseSpriteSize,
		y + (baseSpriteSize / 2),
		math.pi / 2,
		1,
		1,
		baseSpriteSize / 2,
		baseSpriteSize / 2
	)
	love.graphics.draw(
		spriteSet.corner,
		x + (baseSpriteSize / 2) + (totalWidth / PixelPerfectScale) - baseSpriteSize,
		y + (baseSpriteSize / 2) + (totalHeight / PixelPerfectScale) - baseSpriteSize,
		math.pi,
		1,
		1,
		baseSpriteSize / 2,
		baseSpriteSize / 2
	)

	love.graphics.draw(
		spriteSet.corner,
		x + (baseSpriteSize / 2),
		y + (baseSpriteSize / 2) + (totalHeight / PixelPerfectScale) - baseSpriteSize,
		-math.pi / 2,
		1,
		1,
		baseSpriteSize / 2,
		baseSpriteSize / 2
	)

	-- Edges

	local EdgeSize = {
		x = (totalWidth - (2 * spriteSize)),
		y = (totalHeight - (2 * spriteSize)),
	}

	local edgeScale = {
		x = EdgeSize.x / spriteSize,
		y = EdgeSize.y / spriteSize,
	}

	love.graphics.draw(spriteSet.edge, x + baseSpriteSize, y, 0, edgeScale.x, 1, 0, 0)
	love.graphics.draw(
		spriteSet.edge,
		x + (baseSpriteSize / 2) + baseSpriteSize + EdgeSize.x / PixelPerfectScale,
		y + (baseSpriteSize * edgeScale.y / 2) + baseSpriteSize,
		math.pi / 2,
		edgeScale.y,
		1,
		baseSpriteSize / 2,
		baseSpriteSize / 2
	)
	love.graphics.draw(
		spriteSet.edge,
		x + (baseSpriteSize * edgeScale.x / 2) + baseSpriteSize,
		y + (baseSpriteSize / 2) + baseSpriteSize + EdgeSize.y / PixelPerfectScale,
		math.pi,
		edgeScale.x,
		1,
		baseSpriteSize / 2,
		baseSpriteSize / 2
	)
	love.graphics.draw(
		spriteSet.edge,
		x + (baseSpriteSize / 2),
		y + (baseSpriteSize * edgeScale.y / 2) + baseSpriteSize,
		-math.pi / 2,
		edgeScale.y,
		1,
		baseSpriteSize / 2,
		baseSpriteSize / 2
	)

	-- Center

	love.graphics.draw(spriteSet.center, x + baseSpriteSize, y + baseSpriteSize, 0, edgeScale.x, edgeScale.y)

	love.graphics.pop()
end

function drawButton(text, x, y, onPressed)
	local width = 2 * MARGIN * Scale + Font:getWidth(text)
	local height = 2 * MARGIN * Scale + Font:getHeight(text)
	local mx, my = love.mouse.getPosition()
	local sprite = Sprites.button
	local hot = mx > x and mx < x + width and my > y and my < y + height
	if hot then
		sprite = Sprites.buttonHot
	end
	drawBox(sprite, x, y, width, height)
	love.graphics.print(
		{ { 0, 0, 0, 1 }, text },
		x + (width / 2) - (Font:getWidth(text) / 2),
		y + (height / 2) - (Font:getHeight(text) / 2)
	)

	if lastMouseState and not currentMouseState and DialogOpen and hot then
		onPressed()
	end
end
