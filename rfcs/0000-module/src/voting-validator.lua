-- 创建 Poll
local function validate_creating_poll(module_id, group)
  if
    #group == 1 and
    group[1].input == nil and
    group[1].output ~= nil and
    group[1].output.module_id == module_id
  then
    local output_data = load(group[1].output.data)()

    if output_data.type == "Poll" then
      return output_data.choices_amount > 0 and
        output_data.tally_start > 0 and
        output_data.tally_end > output_data.tally_start
    end
  end

  return false
end

-- 销毁 Poll
local function validate_destroying_poll(module_id, group)
  if
    #group == 1 and
    group[1].input ~= nil and
    group[1].input.module_id == module_id
  then
    local input_data = load(group[1].input.data)()

    return input_data.type == "Poll"
  end

  return false
end

-- 创建 Vote
local function validate_creating_vote(module_id, group)
  if
    #group == 1 and
    group[1].input == nil and
    group[1].output ~= nil and
    group[1].output.module_id == module_id
  then
    local output_data = load(group[1].output.data)()

    if output_data.type == "Vote" then
      return output_data.poll_outpoint ~= nil and
        output_data.in_tally == false
    end
  end

  return false
end

-- 销毁 Vote
local function validate_destroying_vote(module_id, group)
  if
    #group == 1 and
    group[1].input ~= nil and
    group[1].input.module_id == module_id
  then
    local input_data = load(group[1].input.data)()

    return input_data.type == "Vote"
  end

  return false
end

-- 统票
local function validate_creating_tally(module_id, group)
  if
    #group > 1 and
    group[1].input ~= nil and
    group[1].input.module_id == module_id and
    group[1].output ~= nil and
    group[1].output.module_id == module_id
  then
    local poll = group[1].input
    local tally = group[1].output
    local poll_data = load(poll.data)()
    local tally_data = load(tally.data)()

    if poll_data.type ~= "Poll" or
      tally_data.type ~= "Tally" or
      tally_data.poll_start ~= poll.height or
      tally_data.tally_start ~= poll_data.tally_start or
      tally_data.poll_outpoint == nil or
      tally_data.poll_outpoint.transaction_hash = poll.outpoint.transaction_hash or
      tally_data.poll_outpoint.cell_index = poll.outpoint.cell_index or
    then
      return false
    end

    local reult = {}
    for i = 1, poll.choices_amount do
      result[i] = 0
    end
    for i = 2, #group do
      if group[i].input == nil or
        group[i].input.module_id ~= module_id or
        group[i].output == nil or
        group[i].output.module_id ~= module_id
      then
        return false
      end
      local vote_in = group[i].input
      local vote_in_data = load(vote_in.data)()
      local vote_out = group[i].output
      local vote_out_data = load(vote_out.data)()

      if vote_data.type == "Vote" and
        vote_in_data.choice >= 1 and
        vote_in_data.choice <= poll_data.choices_amount and
        vote_in_data.in_tally == false and
        vote_out_data.in_tally == true and
        vote_in.height > tally_data.poll_start and
        vote_in.height < tally_data.tally_start and
        vote_in.poll_inpoint.transaction_hash == tally_data.poll_inpoint.transaction_hash and
        vote_in.poll_inpoint.cell_index == tally_data.poll_inpoint.cell_index
      then
        result[vote_in_data.choice] = result[vote_in_data.choice] + vote_in.capacity * (poll_data.tally_end - vote_in.height)
      end
    end

    if #tally_data.result ~= #result then
      return false
    end
    for i = 1, #result do
      if result[i] ~= tally_data.result[i] then
        return false
      end
    end

    return true
  end

  return false
end

-- 举报统票
local function validate_slashing_tally(module_id, group)
  if
    #group == 1 and
    group[1].input ~= nil and
    group[1].input.module_id == module_id and
    group[1].output == nil and
    group[2].input ~= nil and
    group[2].input.module_id == module_id and
    group[2].output ~= nil and
    group[2].output.module_id == module_id
  then
    local tally = group[1].input
    local vote_in = group[2].input
    local vote_out = group[2].output

    local tally_data = load(tally.data)()
    local vote_in_data = load(vote_in.data)()
    local vote_out_data = load(vote_out.data)()

    if tally.type ~= "Tally" or
      vote_in_data.type ~= "Vote" or
      vote_out_data.type ~= "Vote"
    then
      return false
    end

    return vote_in_data.in_tally == false and
      vote_in.height
      vote_in.height > tally_data.poll_start and
      vote_in.height < tally_data.tally_start and
      tally_data.poll_outpoint ~= nil and
      vote_in_data.poll_outpoint.transaction_hash == tally_data.poll_outpoint.transaction_hash and
      vote_in_data.poll_outpoint.cell_index == tally_data.poll_outpoint.cell_index
  end

  return false
end

-- 取消统票
local function validate_destroying_tally(module_id, group)
  if
    #group == 1 and
    group[1].input ~= nil and
    group[1].input.module_id == module_id
  then
    local input_data = load(group[1].input.data)()

    if input_data.type ~= "Tally" then
      return false
    end

    -- Transform
    if group[2].output ~= nil then
      local output_data = load(group[1].output.data)()
      return input_data.result ~= nil and output_data.result == nil
    end

    -- Destroy
    return input_data.result == nil
  end

  return false
end

return function(module_id, group)
  return validate_creating_poll(module_id, group) or
    validate_destroying_poll(module_id, group) or
    validate_creating_vote(module_id, group) or
    validate_destroying_vote(module_id, group) or
    validate_creating_tally(module_id, group) or
    validate_slashing_tally(module_id, group) or
    validate_destroying_tally(module_id, group)
end
