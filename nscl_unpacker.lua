require("binaryreader")

local DecodeBytes = string.unpack

requirep("nscl_unpacker/nscl_itempackets")

--CompileC("./2011_declasses.cxx", "nscl_2011_detclasses")
--LoadLib("./2011_declasses_cxx.so", "nscl_2011_detclasses")

tbranches = nil
curr_file_pos = 0

logfile = assert(io.open("./nsclunpack.log", "w"))
warning_msgs = {[1] = {msg = "XLM Buffer too small", count = 0}}

local function ReadPacketHeader(bdata)
  local plength, ptype = DecodeBytes("I4I4", bdata)

  return plength, ptype
end

function UnpackPacket(binData, ptype, plength)
  local pname = evtPacketTypes[ptype].name
  local pitemtype = evtPacketTypes[ptype].itemtype
  local unpackfn = evtPacketTypes[ptype].unpackfn

  if nscl_buffer and pitemtype == "PHYSICS_EVENT" then 
    nscl_buffer.pitemtype = pitemtype
  elseif scaler_buffer and pitemtype == "SCALER" then 
    table.insert(scaler_buffer, {pitemtype=pitemtype})
  end

  #if debug_log > 0 
  if not ignore_packets[pitemtype] then print("------------- Packet Name:", pname, "( item type =", pitemtype, ") -------------------") end
  #endif

  data = {}

  if unpackfn ~= nil then
    data = unpackfn(binData, plength)
  end

  #if debug_log > 0
  if not ignore_packets[pitemtype] then
    if pitemtype == "CHANGE_STATE" then
      print("Run Number:", data.run)
      print("Time Offset:", data.toff)
      print("Timestamp:", data.ts)
      print("Title:", data.title)
    end
  end
  #endif

  return pitemtype or "unknown"
end

function ReadNextPacket(bfile, plength, ptype)
  if plength == nil or ptype == nil then
    plength, ptype = -1, -1

    local pheader = bfile:read(8)

    if pheader == nil then
      return nil
    end

    plength, ptype = ReadPacketHeader(pheader)
  end

  curr_file_pos = bfile:seek("cur")-8

  if evtPacketTypes[ptype].name == "PHYSICS_EVENT" and nscl_buffer then 
    if nscl_buffer.this_packet_pos then
      nscl_buffer.prev_packet_pos = nscl_buffer.this_packet_pos
    end
    nscl_buffer.this_packet_pos = bfile:seek("cur")
  elseif evtPacketTypes[ptype].name == "PHYSICS_EVENT_COUNT" and physics_count_buffer then
    physics_count_buffer = {}
  elseif evtPacketTypes[ptype] == nil then
    print("WARNING: attempt to read a packet but the type is unknown =>", ptype)
  end

  #if debug_log > 0 
  print("*************************************************************")
  print("Raw packet dump info at", curr_file_pos, PrintHexa(curr_file_pos), ptype, plength) 
  #endif

  local binData = bfile:read(plength-8)

  return UnpackPacket(binData, ptype, plength-8)
end

function IdentifyAndUnpack(binData, offset)
  local plength, ptype = -1, -1

  plength, ptype = ReadPacketHeader(binData:sub(offset+1,offset+8))

  if not plength then
    return nil, offset
  elseif plength > binData:len()-offset then
--    print("WARNING: packet length bigger than the provided data", ptype, plength, binData:len()-offset)
    return nil, plength-(binData:len()-offset)
  end

  #if debug_log > 0 
  print("*************************************************************")
  print("Raw packet dump info", ptype, plength)
  #endif

  return UnpackPacket(binData:sub(offset+9), ptype, plength-8), plength
end

function ConvertToROOT(input_file, output_file, initial_offset, maxEvt)
  local ret = os.execute("date")

  local bfile = io.open(input_file, "rb")
  #if debug_log == 0 
  logfile = io.open(output_file..".log", "w")
  #else
  logfile = io.open("debug_log.log", "w")
  #endif

  local input_length = bfile:seek("end")
  bfile:seek("set", initial_offset or 0)
  curr_file_pos = bfile:seek("cur")

  local outf = TFile(output_file..".root", "recreate")

  local tree = TTree({name="Kr86", title="Dave's 86Kr tree"})

  local si = tree:NewBranch("Si", "ASICHit")
  local adc = tree:NewBranch("ADC", "CAENHit")
  local tdc = tree:NewBranch("TDC", "CAENHit")
  local trig = tree:NewBranch("Trig", "TriggerPack")
  local tof = tree:NewBranch("Tof", "TOFPack")
  local scint = tree:NewBranch("Scint", "ScintPack")
  local crdc = tree:NewBranch("Crdc", "CRDCPack")
  local ic = tree:NewBranch("Ic", "ICPack")
  local tppac = tree:NewBranch("Tppac", "TPPACPack")
  local hodo = tree:NewBranch("Hodo", "HodoPack")

  tbranches = tree:GetBranchList()

  local dump_every_pct = 0.005
  local progress = 0
  local itemtype = ReadNextPacket(bfile)

  local pcounter = 0

  while itemtype and (maxEvt == nil or pcounter < maxEvt) do
    #if debug_log == 0
    if progress == 0 or curr_file_pos/input_length > progress+dump_every_pct then
      io.write(string.format("Processed %5.1f%% of the file\r",  progress*100))
      io.flush()
      progress = progress+dump_every_pct
    end
    #endif

    if itemtype == "PHYSICS_EVENT" then
      tree:Fill()
      tree:Reset()
    end

    pcounter = pcounter+1

    itemtype = ReadNextPacket(bfile)
  end

  print("")

  print("Error lof summary:")
  for k, v in pairs(warning_msgs) do
    if v.count > 0 then
      print(v.msg, "=>", v.count)
    end
  end

  ret = os.execute("date")

  outf:Write()

  outf:Close()
end
