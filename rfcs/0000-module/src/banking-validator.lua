return function(module_id, group)
  -- 统计 Balance，输入 Cell value 为负，输出 Cell value 为正，统计完必须满足仍然为 0
  local balance = 0
  for _, op in ipairs(group) do
    if op.input then
      local input_cell = op.input.cell
      local input_data = load(input_cell.data)()

      if input_cell.module_id == module_id then
        if input_data.type == "Coin" then
          -- 输入 Cell value
          balance = balance - input_data.value
        else
          -- unknown type
          return false
        end
      else if input_cell.module_id == 0 then
        if input_data.type == "MintToken" then
          -- MintToken 相当额外的输入 Cell value，所以计为负数
          balance = balance - input_data.value
        else if input_data.type == "BurnToken" then
          -- BurnToken 需要抵消部分输入 Cell 的 value，所以计为正数
          balance = balance + input_data.value
        else
          -- unknown type
          return false
        end
      else
        -- unknown module
        return false
      end

    end
    if op.output then
      local output_cell = op.output.cell

      if output_cell.module_id == module_id then
        local output_data = load(input_cell.data)()
        if output_data.type == "Coin" then
          -- 输出 Cell value
          balance = balance + output_data.value
        else
          -- unknown type
          return false
        end
      end
    end

    return balance == 0
  end
end
