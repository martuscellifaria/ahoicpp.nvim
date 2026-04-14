-- AhoiCpp
-- Developed by Alexandre Martuscelli Faria
-- Copyright 2026
-- License MIT

local utils = require("ahoicpp.utils")

return {
	file_exists = utils.file_exists,
	write_file = utils.write_file,
	update_file = utils.update_file,
	read_file = utils.read_file,
	dir_exists = utils.dir_exists,
	get_directories = utils.get_directories,
	create_dir = utils.create_dir,
	utils = {
		is_valid_class_name = utils.is_valid_class_name,
		is_valid_directory_name = utils.is_valid_directory_name,
	},
}
