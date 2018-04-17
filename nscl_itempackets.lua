requirep("nscl_unpacker/nscl_physicspackets")

local DecodeBytes = string.unpack

-- **************** CHANGE STATE ITEM ******************** --

local changestate_ts_fmt = "I4"

if NSCL_UNPACKER.NSCL_DAQ_VERSION >= 11.0 then
  changestate_ts_fmt = "J"
end

local function UnpackChangeStateItem(binData, plength)
  local runNbr, timeOffset, timeStamp, runTitle, offset

  runNbr, timeOffset, timeStamp, runTitle, offset = DecodeBytes("I4I4Jx", binData)

  return {run = runNbr, toff = timeOffset, ts = timeStamp, title = runTitle}
end

-- **************** TEXT ITEM ******************** --

local function UnpackTextItem(binData, plength)

end

-- **************** SCALER ITEM ******************** --

local function UnpackScalerItem(binData, plength)
  local data, offset = {0, 0, 0, 0, 0, 0}

  if NSCL_UNPACKER.NSCL_DAQ_VERSION >= 11.0 then
    data[1], data[2], data[3], data[4], offset = DecodeBytes("I4JI4I4", binData)

    if scaler_buffer then
      scaler_buffer[#scaler_buffer].timestamp = data[2]
--      print("SCALER", scaler_buffer[#scaler_buffer].timestamp)

--      if #scaler_buffer > 30 then
--        table.remove(scaler_buffer, 1)
--      end
    end

    #if debug_log >= 1
    print("  -> body header size =", data[1])
    print("  -> timestamp =", data[2])
    print("  -> source id =", data[3])
    print("  -> barrier type =", data[4])
    #endif
  end

  data[1], data[2], data[3], data[4], data[5], data[6], offset = DecodeBytes("I4I4I4I4I4I4", binData, offset)

  #if debug_log >= 1
--  if true then
  print("  -> interval start =", data[1])
  print("  -> interval end =", data[2])
  print("  -> timestamp (again?) =", data[3])
  print("  -> Interval divisor =", data[4])
  print("  -> Scaler count =", data[5])
  print("  -> Incremental? =", data[6])
  #endif

  for i=1, (plength-20-6*4)/4 do
    data, offset = DecodeBytes("I4", binData, offset)
    #if debug_log >= 1 
    print("  -------> scaler value =", data)	
    #endif
--    if true then print("  -------> scaler value =", data)	end
  end
end

-- **************** PHYSICS EVENT ITEM ******************** --

local function UnpackBodyHeader(data, offset, skip)
  local body_header = {}
  body_header.size, offset = DecodeBytes("I4", data, offset)

  if body_header.size > 0 then
    if skip then
      return body_header, offset+16
    end

    local timestamp = {}

    if nscl_buffer and nscl_buffer.pitemtype == "PHYSICS_EVENT" then 
      timestamp.low, timestamp.med, timestamp.high, timestamp.veryhigh, offset = DecodeBytes("HHHH", data, offset)

      timestamp.value = timestamp.low + (timestamp.med<<16) + (timestamp.high<<32)

      body_header.timestamp = timestamp.value
    else
      body_header.timestamp, offset = DecodeBytes("J", data, offset)
    end

    body_header.sourceID, body_header.barrierID, offset = DecodeBytes("I4I4", data, offset)

    if nscl_buffer and nscl_buffer.pitemtype == "PHYSICS_EVENT" then
      if nscl_buffer.sourceID == 256 then nscl_buffer.sourceID = nil end
      nscl_buffer["timestamp"..tostring(body_header.sourceID)] = timestamp
      if nscl_buffer.sourceID == nil then 
        nscl_buffer.sourceID = body_header.sourceID 
      else
        nscl_buffer.sourceID = nscl_buffer.sourceID + body_header.sourceID 
      end

--      print(tostring(body_header.sourceID), nscl_buffer[#nscl_buffer].sourceID)
    end
  end

  return body_header, offset
end

local function UnpackFragmentHeader(data, offset)
  local ts, srcid, pl_size, barid

  ts, src_id, pl_size, bar_id, offset = DecodeBytes("JI4I4I4", data, offset)

  return {timestamp = ts, sourceID = src_id, payload_size = pl_size, barrierID = bar_id}, offset
end

local function UnpackPhysicsEventHeaders(bdata, offset)
  local frag_header, item_bytes, item_type

  frag_header, offset = UnpackFragmentHeader(bdata, offset)
  item_bytes, item_type, offset = DecodeBytes("I4I4", bdata, offset)

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
      master_body_header, offset = UnpackBodyHeader(binData, offset, true)

      #if debug_log >= 2
      print("Master Body Header size:", master_body_header.size)
      print("Master Body Header Timestamp:", master_body_header.timestamp)
      print("Master Body Header source ID:", master_body_header.sourceID)
      print("Master Body Header barrier:", master_body_header.barrierID)
      #endif
    end

    body_bytes, offset = DecodeBytes("I", binData, offset)

    #if debug_log >= 2
    print("Total Body Size:", body_bytes)
    #endif
  end

  while offset < bytes_left do
    if NSCL_UNPACKER.PHYSICS_FRAGMENT then
      frag_header, offset = UnpackFragmentHeader(binData, offset)

      item_bytes, item_type, offset = DecodeBytes("II", binData, offset)

      effective_payload_size = item_bytes - 8

      #if debug_log >= 2
      print("Fragment header:")
      print("   -> timestamp:", frag_header.timestamp)
      print("   -> source ID:", frag_header.sourceID)
      print("   -> payload size:", frag_header.payload_size)
      print("   -> barrier:", frag_header.barrierID)
      print("Item Size:", item_bytes)
      print("Item Type:", item_type)
      #endif
    end

    if NSCL_UNPACKER.NSCL_DAQ_VERSION >= 11.0 then
      body_header, offset = UnpackBodyHeader(binData, offset)

      effective_payload_size = effective_payload_size - (body_header.size == 0 and 4 or body_header.size)

      #if debug_log >= 2
      print("Item Body Header size:", body_header.size)
      print("Item Body Header Timestamp:", body_header.timestamp)
      print("Item Body Header source ID:", body_header.sourceID)
      print("Item Body Header barrier:", body_header.barrierID)
      #endif
    end

-- Now we are ready to read the fragment payload

    local ptag = NSCL_UNPACKER.IdentifyPacket(frag_header, binData, offset, 40)

    #if debug_log >= 2
    print("Effective Payload Size:", effective_payload_size)
    print("Identified Packet:", ptag and PrintHexa(ptag, 2), ptag and physicsPacketTypes[ptag].name) 
    #endif

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
    data.body_header_size, offset = DecodeBytes("I4", binData)

    if data.body_header_size == 20 then
      data.body_header_timestamp, data.body_header_sourceID, data.body_header_barrier, offset = DecodeBytes("JI4I4", binData, offset)
    end

    #if debug_log >= 1
    print("  -> body header size =", data.body_header_size)

    if data.body_header_size == 20 then
      print("  ----> timestamp =", data.body_header_timestamp)
      print("  ----> source ID =", data.body_header_sourceID)
      print("  ----> barrier type =", data.body_header_barrier)
    end
    #endif
  end

  data.timestamp_offset, data.timestamp, data.event_count, offset = DecodeBytes("I4JJ", binData, offset)

  #if debug_log >= 1
  print("  -> timestamp offset = ", data.timestamp_offset)
  print("  -> timestamp = ", data.timestamp)
  print("  -> event count = ", data.event_count)
  #endif

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
