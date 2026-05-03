local config = require("ahoicpp.config")
local M = {}

function M.insert_code_with_prompt()
	if config.options.vandamme_endpoint == "" then
		vim.notify("vandamme endpoint not configured.", vim.log.levels.WARN)
		return
	end
	local prompt = vim.fn.input("What should vandamme generate? ")
	if prompt ~= "" then
		M.insert_code(prompt)
	end
end

function M.insert_code(prompt)
	if config.options.vandamme_endpoint == "" then
		vim.notify("vandamme endpoint not configured.", vim.log.levels.WARN)
		return
	end
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row = cursor[1]

	local system_prompt = [[You are a C++ code assistant. You MUST follow these rules EXACTLY:

STYLE RULES (CRITICAL - Violate these and the code will be rejected):
1. ALL functions and variables MUST use snake_case (e.g., split_string, input_file)
2. ALL classes and structs MUST use PascalCase (e.g., StringParser)
3. Use C++23 features when possible
4. NEVER write #include statements as actual code - if headers are needed, write them as comments on separate lines like this:
   // #include <string>
   // #include <vector>

OUTPUT RULES:
- Output ONLY the code to insert
- NO explanations, NO markdown fences, NO extra text
- NO main() function under any circumstances
- NO usage examples under any circumstances, as the file you are writing to may already have an entrypoint.

Remember: snake_case for functions/variables, #include as comment (using // at the beginning). These rules are NON-NEGOTIABLE.]]

	local user_prompt = string.format("Write code for the following task:\n\n%s", prompt)

	local full_prompt = string.format(
		"<|im_start|>system\n%s<|im_end|>\n<|im_start|>user\n%s<|im_end|>\n<|im_start|>assistant\n",
		system_prompt,
		user_prompt
	)

	vim.notify("vandamme thinking...", vim.log.levels.INFO)

	local full_response = {}

	vim.fn.jobstart({
		"curl",
		"-s",
		config.options.vandamme_endpoint,
		"-H",
		"Content-Type: application/json",
		"-d",
		vim.fn.json_encode({
			prompt = full_prompt,
			temperature = config.options.vandamme_temperature,
			max_tokens = config.options.vandamme_max_tokens,
			stop = { "<|im_end|>" },
		}),
	}, {
		on_stdout = function(_, data)
			if data then
				for _, chunk in ipairs(data) do
					if chunk ~= "" then
						table.insert(full_response, chunk)
					end
				end
			end
		end,

		on_exit = function()
			local response = table.concat(full_response)

			if response == "" then
				vim.notify("Empty response from server", vim.log.levels.ERROR)
				return
			end

			local ok, decoded = pcall(vim.fn.json_decode, response)
			if not ok then
				vim.notify("JSON decode failed: " .. tostring(decoded), vim.log.levels.ERROR)
				return
			end

			if not decoded.content then
				vim.notify("No content field in response", vim.log.levels.ERROR)
				return
			end

			local code = decoded.content
			code = code:gsub("^```%w*\n", ""):gsub("\n```$", ""):gsub("^```%w*", ""):gsub("```$", "")
			code = code:match("^%s*(.-)%s*$")

			if not code or code == "" then
				vim.notify("Model returned empty content", vim.log.levels.WARN)
				return
			end

			local code_lines = vim.split(code, "\n")
			vim.schedule(function()
				vim.api.nvim_buf_set_lines(bufnr, row, row, false, code_lines)
				vim.notify("Code inserted", vim.log.levels.INFO)
			end)
		end,
	})
end

function M.explain_selection()
	if config.options.vandamme_endpoint == "" then
		vim.notify("vandamme endpoint not configured.", vim.log.levels.WARN)
		return
	end
	local bufnr = vim.api.nvim_get_current_buf()
	local start_row = vim.fn.line("'<") - 1
	local end_row = vim.fn.line("'>")
	local sel_lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row, false)
	local selection = table.concat(sel_lines, "\n")

	local full_prompt = string.format(
		"<|im_start|>system\nYou explain code concisely. Give a single-line comment explanation.<|im_end|>\n<|im_start|>user\nExplain this C++ code:\n```cpp\n%s\n```<|im_end|>\n<|im_start|>assistant\n",
		selection
	)

	vim.notify("vandamme analyzing...", vim.log.levels.INFO)

	vim.fn.jobstart({
		"curl",
		"-s",
		config.options.vandamme_endpoint,
		"-H",
		"Content-Type: application/json",
		"-d",
		vim.fn.json_encode({
			prompt = full_prompt,
			temperature = 0.1,
			max_tokens = 100,
			stop = { "<|im_end|>" },
		}),
	}, {
		on_stdout = function(_, data)
			if not data then
				return
			end
			local response = table.concat(data)
			local ok, decoded = pcall(vim.fn.json_decode, response)
			if not ok or not decoded.content then
				return
			end

			local explanation = decoded.content:gsub("^%s*//%s*", ""):match("^%s*(.-)%s*$")
			vim.notify(explanation, vim.log.levels.INFO)
		end,
		on_stderr = function(_, data)
			if data and #data > 0 and data[1] ~= "" then
				vim.notify("Error: " .. table.concat(data), vim.log.levels.ERROR)
			end
		end,
	})
end

return M
