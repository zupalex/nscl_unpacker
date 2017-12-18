require("nscl_unpacker/nscl_physicspackets")

-- **************** CHANGE STATE ITEM ******************** --

local changestate_ts_fmt = "I4"

if NSCL_UNPACKER.NSCL_DAQ_VERSION >= 11.0 then
  changestate_ts_fmt = "J"
end

local function UnpackChangeStateItem(binData, plength)
  local runNbr, timeOffset, timeStamp, runTitle, offset

  runNbr, offset = DecodeBytes(binData, "I4")
  timeOffset, offset = DecodeBytes(binData, "I4", offset)
  timeStamp, offset = DecodeBytes(binData, changestate_ts_fmt, offset)

  runTitle, offset = DecodeBytes(binData, "z", offset)

  return {run = runNbr, toff = timeOffset, ts = timeStamp, title = runTitle}
end

-- **************** TEXT ITEM ******************** --

local function UnpackTextItem(binData, plength)

end

-- **************** SCALER ITEM ******************** --

local function UnpackScalerItem(binData, plength)
  local data, offset

  if NSCL_UNPACKER.NSCL_DAQ_VERSION >= 11.0 then
    data, offset = DecodeBytes(binData, "I4")
    data, offset = DecodeBytes(binData, "J", offset)

    if scaler_buffer then
      scaler_buffer[#scaler_buffer].timestamp = data
--      print("SCALER", scaler_buffer[#scaler_buffer].timestamp)

--      if #scaler_buffer > 30 then
--        table.remove(scaler_buffer, 1)
--      end
    end

    data, offset = DecodeBytes(binData, "I4", offset)
    data, offset = DecodeBytes(binData, "I4", offset)

    if debug_log >= 1 then
      print("  -> body header size =", data)
      print("  -> timestamp =", data)
      print("  -> source id =", data)
      print("  -> barrier type =", data)
    end
  end

  data, offset = DecodeBytes(binData, "I4", offset)
  data, offset = DecodeBytes(binData, "I4", offset)
  data, offset = DecodeBytes(binData, "I4", offset)
  data, offset = DecodeBytes(binData, "I4", offset)
  data, offset = DecodeBytes(binData, "I4", offset)
  data, offset = DecodeBytes(binData, "I4", offset)

  if debug_log >= 1 then
--  if true then
    print("  -> interval start =", data)
    print("  -> interval end =", data)
    print("  -> timestamp (again?) =", data)
    print("  -> Interval divisor =", data)
    print("  -> Scaler count =", data)
    print("  -> Incremental? =", data)
  end

  for i=1, (plength-20-6*4)/4 do
    data, offset = DecodeBytes(binData, "I4", offset)
    if debug_log >= 1 then print("  -------> scaler value =", data)	end
--    if true then print("  -------> scaler value =", data)	end
  end
end

-- **************** PHYSICS EVENT ITEM ******************** --

local function UnpackBodyHeader(data, offset)
  body_header = {}
  body_header.size, offset = DecodeBytes(data, "I4", offset)

  if body_header.size > 0 then
    if nscl_buffer and nscl_buffer[#nscl_buffer].pitemtype == "PHYSICS_EVENT" then 
      local timestamp = {}
      timestamp.low, offset = DecodeBytes(data, "H", offset)
      timestamp.med, offset = DecodeBytes(data, "H", offset)
      timestamp.high, offset = DecodeBytes(data, "H", offset)
      timestamp.veryhigh, offset = DecodeBytes(data, "H", offset)
      timestamp.value = timestamp.low + (timestamp.med<<16) + (timestamp.high<<32)

      nscl_buffer[#nscl_buffer].timestamp=timestamp
      body_header.timestamp = timestamp.low + (timestamp.med<<16) + (timestamp.high<<32)

--      if #nscl_buffer > 6 and body_header.timestamp > nscl_buffer[#nscl_buffer-1].timestamp.low + (nscl_buffer[#nscl_buffer-1].timestamp.med<<16) + (nscl_buffer[#nscl_buffer-1].timestamp.high<<32) + 10^7/30.5 then
--      if #nscl_buffer > 6 then
--        local ts_this = nscl_buffer[#nscl_buffer].timestamp.low + (nscl_buffer[#nscl_buffer].timestamp.med<<16) + (nscl_buffer[#nscl_buffer].timestamp.high<<32)
--        local ts_prev = nscl_buffer[#nscl_buffer-1].timestamp.low + (nscl_buffer[#nscl_buffer-1].timestamp.med<<16) + (nscl_buffer[#nscl_buffer-1].timestamp.high<<32)

----        for i=5,0,-1 do
----          local ts_this = nscl_buffer[#nscl_buffer-i].timestamp.low + (nscl_buffer[#nscl_buffer-i].timestamp.med<<16) + (nscl_buffer[#nscl_buffer-i].timestamp.high<<32)
----          local ts_prev = nscl_buffer[#nscl_buffer-i-1].timestamp.low + (nscl_buffer[#nscl_buffer-i-1].timestamp.med<<16) + (nscl_buffer[#nscl_buffer-i-1].timestamp.high<<32)

------          if scaler_buffer[#scaler_buffer].timestamp < ts_this then 
------            print("SCALER", scaler_buffer[#scaler_buffer].timestamp)
------          end

----          print("PHYSICS_EVENT", ts_this, (#nscl_buffer > 6 and ts_this > ts_prev + 10^7/30.5) and "<=========== JUMP HERE" or "")
----        end

--        print("PHYSICS_EVENT", ts_this, ts_this-ts_prev, (#nscl_buffer > 6 and ts_this > ts_prev + 10^7/30.5) and "<======================= JUMP HERE" or "")
--      elseif #nscl_buffer > 30 then
--        for i=1,15 do
--          table.remove(nscl_buffer, 1)
--        end
--    end
    else
      body_header.timestamp, offset = DecodeBytes(data, "J", offset)
      hist:Fill(body_header.timestamp/100)
    end

    body_header.sourceID, offset = DecodeBytes(data, "I4", offset)
    body_header.barrierID, offset = DecodeBytes(data, "I4", offset)

    if nscl_buffer and nscl_buffer[#nscl_buffer].pitemtype == "PHYSICS_EVENT" then
      if nscl_buffer[#nscl_buffer].sourceID == 256 then nscl_buffer[#nscl_buffer].sourceID = nil end
      nscl_buffer[#nscl_buffer]["timestamp"..tostring(body_header.sourceID)] = nscl_buffer[#nscl_buffer].timestamp
      if nscl_buffer[#nscl_buffer].sourceID == nil then 
        nscl_buffer[#nscl_buffer].sourceID = body_header.sourceID 
      else
        nscl_buffer[#nscl_buffer].sourceID = nscl_buffer[#nscl_buffer].sourceID + body_header.sourceID 
      end

--      print(tostring(body_header.sourceID), nscl_buffer[#nscl_buffer].sourceID)

      nscl_buffer[#nscl_buffer].timestamp = nil
    end
  end

  return body_header, offset
end

local function UnpackFragmentHeader(data, offset)
  local ts, srcid, pl_size, barid

  ts, offset = DecodeBytes(data, "J", offset)
  src_id, offset = DecodeBytes(data, "I4", offset)
  pl_size, offset = DecodeBytes(data, "I4", offset)
  bar_id, offset = DecodeBytes(data, "I4", offset)

  return {timestamp = ts, sourceID = src_id, payload_size = pl_size, barrierID = bar_id}, offset
end

local function UnpackPhysicsEventHeaders(bdata, offset)
  local frag_header, item_bytes, item_type

  frag_header, offset = UnpackFragmentHeader(bdata, offset)
  item_bytes, offset = DecodeBytes(bdata, "I4", offset)
  item_type, offset = DecodeBytes(bdata, "I4", offset)

  return frag_header, item_bytes, item_type, offset
end

function NSCL_UNPACKER.IdentifyPacket(frag_header, data, offset, max_search)
  print("This function is defined in nscl_unpacker.lua but needs to be overridden by the user")
end

local function UnpackPhysicsEventItem(binData, plength)
  local bytes_left = plength

  local physicsData = {}

  local body_bytes, frag_header, item_bytes, item_type, body_header, master_body_header, offset
  offset = 1

-- we need to determine the actual payload size as whatever is after the fragment header is considered payload and we already read some of these bytes
  local effective_payload_size = bytes_left

  if NSCL_UNPACKER.PHYSICS_FRAGMENT then
    if NSCL_UNPACKER.NSCL_DAQ_VERSION >= 11.0 then
      master_body_header, offset = UnpackBodyHeader(binData, offset)

      if debug_log >= 2 then
        print("Master Body Header size:", master_body_header.size)
        print("Master Body Header Timestamp:", master_body_header.timestamp)
        print("Master Body Header source ID:", master_body_header.sourceID)
        print("Master Body Header barrier:", master_body_header.barrierID)
      end
    end

    body_bytes, offset = DecodeBytes(binData, "I", offset)

    if debug_log >= 2 then
      print("Total Body Size:", body_bytes)
    end
  end

  while offset < bytes_left do
    if NSCL_UNPACKER.PHYSICS_FRAGMENT then
      frag_header, offset = UnpackFragmentHeader(binData, offset)

      item_bytes, offset = DecodeBytes(binData, "I", offset)
      item_type, offset = DecodeBytes(binData, "I", offset)

      effective_payload_size = item_bytes - 8

      if debug_log >= 2 then
        print("Fragment header:")
        print("   -> timestamp:", frag_header.timestamp)
        print("   -> source ID:", frag_header.sourceID)
        print("   -> payload size:", frag_header.payload_size)
        print("   -> barrier:", frag_header.barrierID)
        print("Item Size:", item_bytes)
        print("Item Type:", item_type)
      end
    end

    if NSCL_UNPACKER.NSCL_DAQ_VERSION >= 11.0 then
      body_header, offset = UnpackBodyHeader(binData, offset)

      effective_payload_size = effective_payload_size - (body_header.size == 0 and 4 or body_header.size)

      if debug_log >= 2 then
        print("Item Body Header size:", body_header.size)
        print("Item Body Header Timestamp:", body_header.timestamp)
        print("Item Body Header source ID:", body_header.sourceID)
        print("Item Body Header barrier:", body_header.barrierID)
      end
    end

-- Now we are ready to read the fragment payload

    local ptag = NSCL_UNPACKER.IdentifyPacket(frag_header, binData, offset, 40)

    if debug_log >= 2 then
      print("Effective Payload Size:", effective_payload_size)
      print("Identified Packet:", ptag and PrintHexa(ptag, 2), ptag and physicsPacketTypes[ptag].name) 
    end

--    ptag=nil

    if ptag and physicsPacketTypes[ptag] and physicsPacketTypes[ptag].fn then
      local phys_evt_packet
      offset = physicsPacketTypes[ptag].fn(binData, offset, effective_payload_size)
      table.insert(physicsData, ptag)
    else
--      logfile:write("Unknown item type (", item_type, ") encountered @ ", curr_file_pos, " - address: ", PrintHexa(curr_file_pos), " -\n") 
      offset = offset+effective_payload_size
    end
  end

  return physicsData
end

-- **************** PHYSICS EVENT COUNT ITEM ******************** --

local function UnpackPhysicsEventCountItem(binData, plength)
  local data, offset = {}, nil

  if NSCL_UNPACKER.NSCL_DAQ_VERSION >= 11.0 then
    data.body_header_size, offset = DecodeBytes(binData, "I4")

    if data.body_header_size == 20 then
      data.body_header_timestamp, offset = DecodeBytes(binData, "J", offset)
      data.body_header_sourceID, offset = DecodeBytes(binData, "I4", offset)
      data.body_header_barrier, offset = DecodeBytes(binData, "I4", offset)
    end

    if debug_log >= 1 then
      print("  -> body header size =", data.body_header_size)

      if data.body_header_size == 20 then
        print("  ----> timestamp =", data.body_header_timestamp)
        print("  ----> source ID =", data.body_header_sourceID)
        print("  ----> barrier type =", data.body_header_barrier)
      end
    end
  end

  data.timestamp_offset, offset = DecodeBytes(binData, "I4", offset)
  data.timestamp, offset = DecodeBytes(binData, "J", offset)
  data.event_count, offset = DecodeBytes(binData, "J", offset)

  if debug_log >= 1 then
    print("  -> timestamp offset = ", data.timestamp_offset)
    print("  -> timestamp = ", data.timestamp)
    print("  -> event count = ", data.event_count)
  end

  if physics_count_buffer then
    physics_count_buffer = data
  end
end

-- **************** EVENT BUILDER FRAGMENT ******************** --

local function UnpackEventBuilderFragment(binData, plength)

end

evtPacketTypes = {
  [1] = {name = "BEGIN_RUN", itemtype = "CHANGE_STATE", unpackfn = UnpackChangeStateItem},
  [2] = {name = "END_RUN", itemtype = "CHANGE_STATE", unpackfn = UnpackChangeStateItem},
  [3] = {name = "PAUSE_RUN", itemtype = "CHANGE_STATE", unpackfn = UnpackChangeStateItem},
  [4] = {name = "RESUME_RUN", itemtype = "CHANGE_STATE", unpackfn = UnpackChangeStateItem},

  [10] = {name = "PACKET_TYPES", itemtype = "TEXT", unpackfn = UnpackTextItem},
  [11] = {name = "MONITORED_VARIABLES", itemtype = "TEXT", unpackfn = UnpackTextItem},
  [12] = {name = "RING_FORMAT", itemtype = "TEXT", unpackfn = UnpackTextItem},

  [20] = {name = "PERIODIC_SCALERS", itemtype = "SCALER", unpackfn = UnpackScalerItem},

  [30] = {name = "PHYSICS_EVENT", itemtype = "PHYSICS_EVENT", unpackfn = UnpackPhysicsEventItem},

  [31] = {name = "PHYSICS_EVENT_COUNT", itemtype = "PHYSICS_EVENT_COUNT", unpackfn = UnpackPhysicsEventCountItem},

  [40] = {name = "EVB_FRAGMENT", itemtype = "EVENT_BUILDER_FRAGMENT", unpackfn = UnpackEventBuilderFragment},
  [41] = {name = "EVB_UNKNOWN_PAYLOAD", itemtype = "EVENT_BUILDER_FRAGMENT", unpackfn = UnpackEventBuilderFragment},
  [42] = {name = "EVB_GLOM_INFO", itemtype = "EVENT_BUILDER_FRAGMENT", unpackfn = UnpackEventBuilderFragment},
}
