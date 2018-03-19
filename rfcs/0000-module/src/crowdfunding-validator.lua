return function(module_id, group)
  if
    #group == 1 and
    group[1].input == nil and
    group[1].output ~= nil and
    group[1].output.module_id == module_id
  then
    local output_data = load(group[1].output.data)()

    if output_data.type == "Fund" then
      -- 发起众筹
      return output_data.target and output_data.target > 0
    else if output_data.type == "Share" then
      -- 申领份额
      return output_data.fund_outpoint != nil and
        output_data.fund_outpoint.transaction_hash != nil and
        output_data.fund_outpoint.cell_index != nil and
    end
  end

  if
    #group == 1 and
    group[1].output == nil and
    group[1].input ~= nil and
    group[1].input.module_id == module_id
  then
    local input_data = load(group[1].input.data)()

    if output_data.type == "Fund" then
      -- 取消众筹
      return true
    else if output_data.type == "Share" then
      -- 取回份额
      return output_data.fund_outpoint = nil
    end
  end

  -- 取消份额
  if
    #group == 1 and
    group[1].input ~= nil and
    group[2].input.module_id == module_id and
    group[1].output ~= nil and
    group[2].output.module_id == module_id
  then
    return input_data.type == "Share" and output_data.type == "Share"
  end

  -- 完成众筹
  if #group > 1 and
    group[1].input ~= nil and
    group[1].input.module_id == module_id and
    group[1].output == nil
  then
    local fund_cell = group[1]
    local fund_data = load(fund_cell.data)()
    if fund_data.type ~= "Fund" then
      return false
    end

    local remaining_target = fund_data.target
    for i = 2, #group do
      local share_cell = group[i]
      if share_cell.input == nil or
        share_cell.output ~= nil or
        share_cell.input.module_id ~= module_id
      then
        return false
      end
      local share_data = load(share_cell.data)()
      if share_data.type ~= "Share" or
        share_data.fund_outpoint == nil or 
        share_data.fund_outpoint.transaction_hash ~= fund_cell.outpoint.transaction_hash or 
        share_data.fund_outpoint.cell_index ~= fund_cell.outpoint.cell_index
      then
        return false
      end
      remaining_target = remaining_target - share_cell.capacity
    end

    return remaining_target <= 0
  end

  return false
end
