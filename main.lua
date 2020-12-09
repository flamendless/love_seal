local love_seal = require("love_seal")

local assets = {
	{
		"test1.png",
		"test_assets/test1.png",
	},
	{
		"test2.png",
		"test_assets/test2.png",
	},
	{
		"test3.png",
		"test_assets/test3.png",
	},
}

io.stdout:setvbuf("no")

local images = {}
local unpacked_images
local headers = ""

function love.load()
	-- USAGE
	local output_filename = "out.dat"

	love_seal.pack_png("brbl", assets, output_filename)
	unpacked_images = love_seal.unpack_png("brbl", output_filename)

	-- BELOW ARE FOR DEBUGGING ONLY
	-- load the images the regular way
	for i, v in ipairs(assets) do
		images[i] = love.graphics.newImage(v[2])
	end

	-- for printing the contents of the custom data file
	local file = love.filesystem.newFileData(output_filename)
	local count, i_count = love.data.unpack("<I4", file)
	local header, i_header = love.data.unpack("<s4", file, i_count)

	headers = headers .. tostring(count) .. " " .. header .. "\n"

	local offset = i_header

	for i = 1, count do
		local size, i_size = love.data.unpack("<I4", file, offset)
		offset = i_size

		local filename, i_filename = love.data.unpack("<s4", file, offset)
		offset = i_filename

		local data_view = love.data.newDataView(file, offset - 1, size)
		offset = offset + size

		local data = love.data.encode("string", "base64", data_view:getString())
		data = data:sub(1, 128) .. "...(truncated)"

		headers = headers .. tostring(size) .. " " .. filename .. " " .. data .. "\n"
	end
end

function love.draw()
	local x = 0
	local y = 0
	love.graphics.print("Original images")
	y = y + 32
	for _, img in ipairs(images) do
		love.graphics.draw(img, x, 32)
		x = x + img:getWidth()
		y = math.max(y, img:getHeight())
	end

	local x2 = 0
	local y2 = y + 64
	love.graphics.print("Unpacked images", x2, y2)
	y2 = y2 + 32
	for _, v in ipairs(unpacked_images) do
		local img = v[2]
		love.graphics.draw(img, x2, y2)
		x2 = x2 + img:getWidth()
	end

	local x3 = love.graphics.getWidth() * 0.45
	love.graphics.printf(headers, x3, 32, love.graphics.getWidth()/2)
end
