local love_seal = {}

local ld = love.data
local lf = love.filesystem
local li = love.image
local lg = love.graphics

local format = string.format

local function get_header(file)
	assert(file:type() == "FileData")
	local count, i_count = ld.unpack("<I4", file)
	local header, i_header = ld.unpack("<s4", file, i_count)

	return header, count, i_header
end

local function pack_to_file(file, data_format, to_pack)
	assert(file:type() == "File")
	assert(type(data_format) == "string")
	assert(type(to_pack) == "string" or type(to_pack) == "number")

	local data = ld.pack("data", data_format, to_pack)
	local res, err = file:write(data)

	if not res then error(err) end
end

function love_seal.pack_png(magic_header, t_png, output_filename)
	assert(type(magic_header) == "string")
	assert(type(t_png) == "table")
	assert(type(output_filename) == "string")

	print("Packing to " .. output_filename)

	if lf.getInfo(output_filename) then lf.remove(output_filename) end

	local file_out = lf.newFile(output_filename, "w")
	local count = #t_png

	pack_to_file(file_out, "<I4", count)
	pack_to_file(file_out, "<s4", magic_header)

	for i, v in ipairs(t_png) do
		local filename = v[1]
		local filepath = v[2]
		local data = lf.read("data", filepath)
		local size = data:getSize()

		pack_to_file(file_out, "<I4", size)
		pack_to_file(file_out, "<s4", filename)
		file_out:write(data)

		print(format("Packed(#%d), filename = %s, filepath = %s, size = %d",
			i, filename, filepath, size))
	end
end

function love_seal.unpack_png(magic_header, packed_filename)
	assert(type(magic_header) == "string")
	assert(type(packed_filename) == "string")

	print("Unpacking from " .. packed_filename)

	local images = {}
	local file = lf.newFileData(packed_filename)
	local header, count, index = get_header(file)
	local offset = index

	assert(header == magic_header)
	print(format("header(client): %s, header(packed): %s", magic_header, header))

	for i = 1, count do
		local size, i_size = ld.unpack("<I4", file, offset)
		offset = i_size

		local filename, i_filename = ld.unpack("<s4", file, offset)
		offset = i_filename

		local data_view = ld.newDataView(file, offset - 1, size)
		offset = offset + size

		local data_view_size = data_view:getSize()

		assert(data_view_size == size)

		local img_data = li.newImageData(data_view)
		local img = lg.newImage(img_data)
		images[i] = { filename, img }

		print(string.format("Unpacked(%d), filename = %s, size = %s",
			i, filename, data_view_size))
	end

	return images
end

return love_seal
