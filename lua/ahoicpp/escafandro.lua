local config = require("ahoicpp.config")

local M = {}

M.escafandro_requested = false

function M.insert_code(prompt)
	if M.escafandro_requested then
		vim.notify("Waiting for other Escafandro request. Please wait.", vim.log.levels.WARN)
		return
	end
	if config.options.escafandro.ip == "" then
		vim.notify("escafandro endpoint not configured.", vim.log.levels.WARN)
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
5. ALL member variable names must end with the suffix _. DO NOT PREFIX IT WITH m_ under any circumstances.

OUTPUT RULES:
- Output ONLY the code to insert
- NO explanations, NO markdown fences, NO extra text
- NO main() function under any circumstances
- NO usage examples under any circumstances, as the file you are writing to may already have an entrypoint.

Remember: snake_case for functions/variables, #include as comment (using // at the beginning), member variable names must end with _. These rules are NON-NEGOTIABLE.]]

	local user_prompt = string.format("Write code for the following task:\n\n%s", prompt)

	local full_prompt = string.format(
		"<|im_start|>system\n%s<|im_end|>\n<|im_start|>user\n%s<|im_end|>\n<|im_start|>assistant\n",
		system_prompt,
		user_prompt
	)

	vim.notify("Escafandro thinking...", vim.log.levels.INFO)

	local full_response = {}

	M.escafandro_requested = true
	if config.options.escafandro.engine == "llamacpp" then
		vim.fn.jobstart({
			"curl",
			"-s",
			config.options.escafandro.ip .. "/completion",
			"-H",
			"Content-Type: application/json",
			"-d",
			vim.fn.json_encode({
				prompt = full_prompt,
				temperature = 0.2,
				max_tokens = config.options.escafandro.max_tokens,
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
				M.escafandro_requested = false
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
	elseif config.options.escafandro.engine == "ollama" then
		vim.fn.jobstart({
			"curl",
			"-s",
			config.options.escafandro.ip .. "/api/generate",
			"-H",
			"Content-Type: application/json",
			"-d",
			vim.fn.json_encode({
				prompt = full_prompt,
				max_tokens = config.options.escafandro.max_tokens,
				stop = { "<|im_end|>" },
				stream = false,
				model = config.options.escafandro.model,
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
				M.escafandro_requested = false
				if response == "" then
					vim.notify("Empty response from Escafandro server. Is it running?", vim.log.levels.ERROR)
					return
				end

				local ok, decoded = pcall(vim.fn.json_decode, response)
				if not ok then
					vim.notify("JSON decode failed: " .. tostring(decoded), vim.log.levels.ERROR)
					return
				end

				if not decoded.response then
					vim.notify("No response field in response", vim.log.levels.ERROR)
					return
				end

				local code = decoded.response
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
end

function M.select_text()
	vim.cmd("normal! \27")
	local bufnr = vim.api.nvim_get_current_buf()
	local start_row = vim.fn.line("'<") - 1
	local end_row = vim.fn.line("'>")
	local sel_lines = vim.api.nvim_buf_get_lines(bufnr, start_row, end_row, false)
	local selection = table.concat(sel_lines, "\n")
	return selection
end

function M.refactor_selection()
	if config.options.escafandro.ip == "" then
		vim.notify("Escafandro endpoint not configured.", vim.log.levels.WARN)
		return
	end
	if M.escafandro_requested then
		vim.notify("Waiting for other Escafandro request. Please wait.", vim.log.levels.WARN)
		return
	end
	local selection = M.select_text()
	if selection and selection ~= "" then
		local prompt = string.format("Refactor this code: \n%s\n", selection)
		M.insert_code(prompt)
	end
end

function M.explain_selection(callback)
	if config.options.escafandro.ip == "" then
		vim.notify("Escafandro endpoint not configured.", vim.log.levels.WARN)
		return
	end
	if M.escafandro_requested then
		vim.notify("Waiting for other Escafandro request. Please wait.", vim.log.levels.WARN)
		return
	end
	local selection = M.select_text()
	local full_prompt = string.format(
		"<|im_start|>system\nYou explain code concisely. Give a few lines explanation. No code, just the explanation. If you find an error or are explaining about an error, you must give the line and the file name if applicable.<|im_end|>\n<|im_start|>user\nExplain this C++ code or compilation error:\n```cpp\n%s\n```<|im_end|>\n<|im_start|>assistant\n",
		selection
	)

	vim.notify("Escafandro analyzing...", vim.log.levels.INFO)

	M.request_explanation(full_prompt, callback)
end

function M.explain_build_message(build_message, callback)
	if config.options.escafandro.ip == "" then
		vim.notify("Escafandro endpoint not configured.", vim.log.levels.WARN)
		return
	end
	if M.escafandro_requested then
		vim.notify("Waiting for other Escafandro request. Please wait.", vim.log.levels.WARN)
		return
	end
	local full_prompt = string.format(
		"<|im_start|>system\nYou explain C++ build error concisely. Give a few lines explanation. Just the explanation. If you are explaining about an error, you must give the line and the file name if applicable.<|im_end|>\n<|im_start|>user\nExplain this C++ build compilation error:\n```cpp\n%s\n```<|im_end|>\n<|im_start|>assistant\n",
		build_message
	)

	vim.notify("Escafandro analyzing... (It may take a while depending on the amount of errors)", vim.log.levels.INFO)

	M.request_explanation(full_prompt, callback)
end

function M.request_explanation(full_prompt, callback)
	M.escafandro_requested = true
	if config.options.escafandro.engine == "llamacpp" then
		vim.fn.jobstart({
			"curl",
			"-s",
			config.options.escafandro.ip .. "/completion",
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
				M.escafandro_requested = false
				if not data then
					return
				end
				local response = table.concat(data)
				local ok, decoded = pcall(vim.fn.json_decode, response)
				if not ok or not decoded.content then
					vim.notify("Empty response from Escafandro server. Is it running?", vim.log.levels.ERROR)
					return
				end

				local explanation = decoded.content:gsub("^%s*//%s*", ""):gsub("[\n\r]+", " "):match("^%s*(.-)%s*$")
				if callback then
					callback(explanation)
				end
				vim.notify("Escafandro finished.", vim.log.levels.INFO)
			end,
			on_stderr = function(_, data)
				M.escafandro_requested = false
				if data and #data > 0 and data[1] ~= "" then
					vim.notify("Error: " .. table.concat(data), vim.log.levels.ERROR)
				end
			end,
		})
	elseif config.options.escafandro.engine == "ollama" then
		vim.fn.jobstart({
			"curl",
			"-s",
			config.options.escafandro.ip .. "/api/generate",
			"-H",
			"Content-Type: application/json",
			"-d",
			vim.fn.json_encode({
				prompt = full_prompt,
				max_tokens = 100,
				stream = false,
				model = config.options.escafandro.model,
				stop = { "<|im_end|>" },
			}),
		}, {
			on_stdout = function(_, data)
				M.escafandro_requested = false
				if not data then
					return
				end
				local response = table.concat(data)
				local ok, decoded = pcall(vim.fn.json_decode, response)
				if not ok or not decoded.response then
					return
				end

				local explanation = decoded.response:gsub("^%s*//%s*", ""):gsub("[\n\r]+", " "):match("^%s*(.-)%s*$")
				if callback then
					callback(explanation)
				end
				vim.notify("Escafandro finished.", vim.log.levels.INFO)
			end,
			on_stderr = function(_, data)
				M.escafandro_requested = false
				if data and #data > 0 and data[1] ~= "" then
					vim.notify("Error: " .. table.concat(data), vim.log.levels.ERROR)
				end
			end,
		})
	end
end

return M
