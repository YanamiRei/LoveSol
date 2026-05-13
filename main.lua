-- GOLF SOLITAIRE

MARGIN = 30
CARD_DIMENSIONS = { x = 60, y = 100 }
CARD_GAP = { x = 20, y = 10 }

Scale = 1

function Shuffle(tbl)
	for i = #tbl, 2, -1 do
		local j = math.random(i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
	return tbl
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
	Deck = GenrateDeck()
	Tableu = DistributeDeck(Deck)

	SetupDrawPositions()
end

function love.update() end

function love.draw() end

function love.resize()
	SetupDrawPositions()
end

function SetupDrawPositions()
	Ww, Wh = love.graphics.getDimensions()

	local abs_width = (2 * MARGIN) + (7 * CARD_DIMENSIONS.x) + (6 * CARD_GAP.x)
	local abs_height = (2 * MARGIN) + (4 * CARD_GAP.y) + CARD_DIMENSIONS.y + MARGIN + CARD_DIMENSIONS.y
	if abs_width > Ww or abs_height > Wh then
		Scale = math.min(Ww / abs_width, Wh / abs_height)
	else
		Scale = 1
	end

	DrawPositions = {}
	for i = 1, 7 do
		table.insert(DrawPositions, {})
	end

	for i = 1, 5 do
		for j = 1, 7 do
			local posn = {}
			posn.x = (MARGIN + ((j - 1) * (CARD_DIMENSIONS.x + CARD_GAP.x)) * Scale)
			posn.y = (MARGIN + ((i - 1) * CARD_GAP.y)) * Scale
			table.insert(DrawPositions[j], posn)
		end
	end

	DrawPositions.stock = { x = MARGIN * Scale, y = Wh - ((CARD_DIMENSIONS.y + MARGIN) * Scale) }
	DrawPositions.Foundation =
		{ x = (MARGIN + CARD_DIMENSIONS.x + CARD_GAP) * Scale, y = Wh - ((CARD_DIMENSIONS.y + MARGIN) * Scale) }
end
