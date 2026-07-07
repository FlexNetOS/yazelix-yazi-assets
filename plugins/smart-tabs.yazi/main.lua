--- @sync entry

local function active_current()
	return cx and cx.active and cx.active.current or nil
end

local function hovered_dir_url()
	local current = active_current()
	local hovered = current and current.hovered or nil
	if hovered and hovered.cha and hovered.cha.is_dir then
		return hovered.url
	end
	return nil
end

local function current_cwd_string()
	local current = active_current()
	if current and current.cwd then
		return tostring(current.cwd)
	end
	return nil
end

local function tab_count()
	return cx and cx.tabs and #cx.tabs or 1
end

local function parse_index(raw)
	local index = tonumber(raw)
	if not index or index < 0 or index % 1 ~= 0 then
		ya.err("smart-tabs: tab index must be a non-negative integer", tostring(raw))
		return nil
	end
	return index
end

local function create_tab()
	local hovered = hovered_dir_url()
	if hovered then
		ya.emit("tab_create", { hovered })
	else
		ya.emit("tab_create", { current = true })
	end
end

local function create_tab_from_current()
	local cwd = current_cwd_string()
	if cwd then
		ya.emit("tab_create", { cwd })
	else
		ya.emit("tab_create", { current = true })
	end
end

local function switch_or_create(raw_index)
	local index = parse_index(raw_index)
	if not index then
		return
	end

	for _ = tab_count(), index do
		create_tab_from_current()
	end
	ya.emit("tab_switch", { index })
end

local function entry(_, job)
	local args = job and job.args or {}
	local command = args[1]

	if not command or command == "create" then
		create_tab()
	elseif command == "switch" then
		switch_or_create(args[2])
	elseif tonumber(command) then
		switch_or_create(command)
	else
		ya.err("smart-tabs: unknown command", tostring(command))
	end
end

local function setup()
end

return {
	entry = entry,
	setup = setup,
}
