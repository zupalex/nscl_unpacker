local OverrideIdentifyPacket = require("nscl_unpacker/packet_identifier.lua")

NSCL_DAQ_VERSION = 11.0

require("nscl_unpacker/nscl_unpacker")
require("nscl_unpacker/nscl_processdata")

OverrideIdentifyPacket("E16025PacketIdentifier")

function StartBufferingRingSelector(mastertask, buf_file_size, source, accept)
  local pipe=AttachOutput(os.getenv("DAQBIN").."/ringselector", "ringselector", 
    {accept, "--non-blocking", source}, {"DAQBIN"})

  local buf_file = assert(io.open("online_buffer/test_buf-0.evt", "wb"))
  local buf_file_num = 0

  while CheckSignals() do
    local data = pipe:WaitAndRead(nil, true)
    buf_file:write(data)

    if buf_file:seek("end") > buf_file_size then
      buf_file:close()
      buf_file_num = buf_file_num+1
      buf_file = assert(io.open("online_buffer/test_buf-"..tostring(buf_file_num)..".evt", "wb"))
      SendSignal(mastertask, "buffilenum", buf_file_num)
    end
  end
end

function StartBufferingAndRead(dump, source)
  local max_buf_file_size, buf_file_num, writer_file_num = 5e7, 0, 0
  os.remove("online_buffer/test_buf-"..tostring(buf_file_num)..".evt")

  local buf_file = io.open("online_buffer/test_buf-"..tostring(buf_file_num)..".evt", "rb")

  if source == nil or source == "masterevb" or source == "meb" or source == "MEB" then
    source = "--source=tcp://spdaq08/masterevb"
    PHYSICS_FRAGMENT = true
  elseif source == "s800filter" then
    source = "--source=tcp://spdaq50/s800filter"
  elseif source == "orruba" then
    source = "--source=tcp://spdaq08/orruba"
  end

  if accept == nil then
    accept = "--accept=PHYSICS_EVENT,PHYSICS_EVENT_COUNT"
  else
    accept = "--accept="..accept
  end

  StartNewTask("buffering", "StartBufferingRingSelector", GetTaskName(), writer_file_num, source, accept)

  if dump then debug_log = 3 end

  nscl_buffer = {}
  scaler_buffer = {}
  physics_count_buffer = {}

  while buf_file == nil do
    sleep(0.1)
    print("waiting for first buffer spill...")
    buf_file = io.open("online_buffer/test_buf-"..tostring(buf_file_num)..".evt", "rb")
  end

  local maxBufSize = 32000
  local binData, fpos = "", 0

  buf_file:seek("set")

  local nevt = 0

  local startingCounts, s800_ev_counts, last_s800_evtnbr, orruba_ev_count, last_orruba_evtnbr, last_print = {}, nil, 0, nil, 0, 0

  local frag_leftover, missing_bytes

  AddSignal("buffilenum", function(num)
      writer_file_num = num
    end)

  local stat_term = MakeSlaveTerm({bgcolor="Grey42", fgcolor="Grey93", fontstyle="Monospace", fontsize=10, geometry="100x15-0+0"})

  local hists

  if debug_log == 0 then
    hists = SetupNSCLHistograms()
  end

  InitOnlineDisplay(hists)

  while CheckSignals() do
    if writer_file_num > buf_file_num and fpos > max_buf_file_size then
      if fpos < buf_file:seek("end") then
        buf_file:seek("cur", fpos)

        local file_tail = buf_file:read("a")

        if frag_leftover then 
          frag_leftover = frag_leftover..file_tail
        else
          frag_leftover = file_tail
        end
      else
        os.remove("online_buffer/test_buf-"..tostring(buf_file_num)..".evt")
        buf_file_num = buf_file_num+1
        buf_file = io.open("online_buffer/test_buf-"..tostring(buf_file_num)..".evt", "rb")
      end
    else
      if frag_leftover then 
        binData = frag_leftover 
        frag_leftover = nil
      end

      local buff_data = buf_file:read(maxBufSize)

      local buff_tbl, buff_size, bytes_read = {}, 0, 0

      if buff_data ~= nil then
        buff_tbl[#buff_tbl+1] = buff_data
        buff_size = buff_size + buff_data:len()
      end

      while buff_size < 8 or (missing_bytes and buff_size < missing_bytes) do
        print("waiting for additional data... current buffer size:", buff_size, "waiting for", missing_bytes and missing_bytes or 8)
        sleep(0.1)
        buff_data = buf_file:read(maxBufSize)
        if buff_data ~= nil then
          buff_tbl[#buff_tbl+1] = buff_data
          buff_size = buff_size +  buff_data:len()
        end
      end

      if missing_bytes then missing_bytes = nil end

      binData = binData .. table.concat(buff_tbl)

      fpos = buf_file:seek("cur")

      local totread, dlength = 0, binData:len()

      while totread < dlength do
        if totread > dlength-8 then
          frag_leftover = binData:sub(totread+1)
          break
        end

        local ptype, bread = IdentifyAndUnpack(binData, totread)

        nevt = nevt+1

        if ptype == nil then
          frag_leftover = binData:sub(totread+1)
          missing_bytes = bread
--        print("end of buffer...")
          sleep(0.1)
          break
        end

        totread = totread+bread

        if ptype == "PHYSICS_EVENT_COUNT" then
          if physics_count_buffer.body_header_size == 0 then
            if startingCounts.s800 == nil then
              startingCounts.s800 = physics_count_buffer.event_count
              s800_ev_counts = 0
              last_s800_evtnbr = startingCounts.s800
            else
              last_s800_evtnbr = physics_count_buffer.event_count
            end
          elseif physics_count_buffer.body_header_sourceID then
            if startingCounts.orruba == nil then
              startingCounts.orruba = physics_count_buffer.event_count
              orruba_ev_counts = 0
              last_orruba_evtnbr = physics_count_buffer.event_count
            else
              last_orruba_evtnbr = physics_count_buffer.event_count
            end
          end

          if ptype == "PHYSICS_EVENT_COUNT" then
            if physics_count_buffer.body_header_size == 0 then
              if startingCounts.s800 == nil then
                startingCounts.s800 = physics_count_buffer.event_count
                s800_ev_counts = 0
                last_s800_evtnbr = startingCounts.s800
              else
                last_s800_evtnbr = physics_count_buffer.event_count
              end
            elseif physics_count_buffer.body_header_sourceID then
              if startingCounts.orruba == nil then
                startingCounts.orruba = physics_count_buffer.event_count
                orruba_ev_counts = 0
                last_orruba_evtnbr = physics_count_buffer.event_count
              else
                last_orruba_evtnbr = physics_count_buffer.event_count
              end
            end
          end
        end
      end

      bread = 0
      totread = 0

      if debug_log == 0 then
--      print(#nscl_buffer)
        ProcessNSCLBuffer(nscl_buffer, hists, nevt)
      end

      if nevt-last_print > 10000 then
        if startingCounts.s800 and startingCounts.orruba then
          stat_term:Write(string.format("Received: S800 => %10d / %10d ||| ORRUBA => %10d / %10d\r", 
              s800_ev_counts, last_s800_evtnbr-startingCounts.s800, 
              orruba_ev_counts, last_orruba_evtnbr-startingCounts.orruba))
        end

        last_print = nevt

        UpdateNSCLHistograms(hists)
      end

      nscl_buffer = {}
      scaler_buffer = {}
      physics_count_buffer = {}
    end
  end
end













----------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------

function Showh(hname, opts)
  SendSignal("rslistener", "display", hname, opts)
end

function Unmaph(hname)
  SendSignal("rslistener", "unmap", hname)
end

function ListHistograms(alias, ...)
  local matches

  if type(alias) == "string" then
    matches = table.pack(alias, ...)
    alias = true
  else
    matches = table.pack(...)
  end

  SendSignal("rslistener", "ls", alias, matches, false)
end

function StartListeningRingSelector(dump, source, accept)
  if source == nil or source == "masterevb" or source == "meb" or source == "MEB" then
    source = "--source=tcp://spdaq08/masterevb"
    PHYSICS_FRAGMENT = true
  elseif source == "s800filter" then
    source = "--source=tcp://spdaq50/s800filter"
  elseif source == "orruba" then
    source = "--source=tcp://spdaq08/orruba"
  end

  if accept == nil then
    accept = "--accept=PHYSICS_EVENT,PHYSICS_EVENT_COUNT"
  else
    accept = "--accept="..accept
  end

  nscl_buffer = {}
  scaler_buffer = {}
  physics_count_buffer = {}

  if dump then debug_log = 3 end

  local hists

  if debug_log == 0 then
    hists = SetupNSCLHistograms()
  end

  InitOnlineDisplay(hists)

  local pipe=AttachOutput(os.getenv("DAQBIN").."/ringselector", "ringselector", 
    {accept, "--non-blocking", source}, {"DAQBIN"})

  local stat_term = MakeSlaveTerm({bgcolor="Purple4", fgcolor="Grey93", fontstyle="Monospace", fontsize=10, geometry="100x15-0+0",
      title="RingSelector Listener Log", label="ringselector log"})

  local data, ptype, dlength, frag_data, frag_length, frag_leftover = nil, nil, 0, {}, {}, nil

  local bread, totread = 0, 0

  local nevt = 0

  local startingCounts, s800_ev_counts, last_s800_evtnbr, orruba_ev_count, last_orruba_evtnbr, last_print = {}, nil, 0, nil, 0, 0

  while CheckSignals() do
--    data = pipe:Read()

    dlength = 0
    frag_data = {}
    frag_length = {}

    if frag_leftover ~= nil then
      frag_data[1] = frag_leftover
      frag_length[1] = frag_leftover:len()
      frag_leftover = nil
    end

    frag_data[#frag_data+1], frag_length[#frag_length+1] = pipe:WaitAndRead(nil, true)

    while frag_length[#frag_length] > 0 do
      dlength = dlength+frag_length[#frag_length]
      frag_data[#frag_data+1], frag_length[#frag_length+1] = pipe:Read()
    end

    data = table.concat(frag_data)

    if dlength > 8 then
      while totread < dlength do
        ptype, bread = IdentifyAndUnpack(data, totread)

        nevt = nevt+1

        if ptype == nil then
          frag_leftover = data:sub(totread+1)
          break
        end

        totread = totread+bread

        if s800_ev_counts and #nscl_buffer>0 and (nscl_buffer[#nscl_buffer].sourceID == 2 or nscl_buffer[#nscl_buffer].sourceID == 2+16) then 
          s800_ev_counts = s800_ev_counts+1
        end

        if orruba_ev_counts and #nscl_buffer>0 and (nscl_buffer[#nscl_buffer].sourceID == 16 or nscl_buffer[#nscl_buffer].sourceID == 2+16) then 
          orruba_ev_counts = orruba_ev_counts+1
        end

        if ptype == "PHYSICS_EVENT_COUNT" then
          if physics_count_buffer.body_header_size == 0 then
            if startingCounts.s800 == nil then
              startingCounts.s800 = physics_count_buffer.event_count
              s800_ev_counts = 0
              last_s800_evtnbr = startingCounts.s800
            else
              last_s800_evtnbr = physics_count_buffer.event_count
            end
          elseif physics_count_buffer.body_header_sourceID then
            if startingCounts.orruba == nil then
              startingCounts.orruba = physics_count_buffer.event_count
              orruba_ev_counts = 0
              last_orruba_evtnbr = physics_count_buffer.event_count
            else
              last_orruba_evtnbr = physics_count_buffer.event_count
            end
          end
        end
      end

      bread = 0
      totread = 0

      if debug_log == 0 then
--      print(#nscl_buffer)
        ProcessNSCLBuffer(nscl_buffer, hists, nevt)
      end
    end

    if nevt-last_print > 10000 then
      if startingCounts.s800 and startingCounts.orruba then
        stat_term:Write(string.format("Received: S800 => %10d / %10d ||| ORRUBA => %10d / %10d\r", 
            s800_ev_counts, last_s800_evtnbr-startingCounts.s800, 
            orruba_ev_counts, last_orruba_evtnbr-startingCounts.orruba))
      end

      last_print = nevt

      UpdateNSCLHistograms(hists)
    end

--    theApp:ProcessEvents()

    nscl_buffer = {}
    scaler_buffer = {}
    physics_count_buffer = {}
end
end

function ReplayNSCLEvt(evtfile, max_packet, skip_to_physics)
  nscl_buffer = {}
  scaler_buffer = {}

  PHYSICS_FRAGMENT = true
--  PHYSICS_FRAGMENT = false

  local s800_file = assert(io.open(evtfile)) 

  local fpos = 0
  local filelength = s800_file:seek("end")
  s800_file:seek("set")

  local packet_counter = 0

  if skip_to_physics then
    while ReadNextPacket(s800_file) ~= "PHYSICS_EVENT" do
      ReadNextPacket(s800_file)
    end
  end

--  debug_log=3
--  debug_log_details.crdc = true

--  local buffile = TFile("buffer.root", "recreate")

  local hists

  if debug_log == 0 then
    hists = SetupNSCLHistograms()
    SetupOfflineCanvas(hists)
  end

--  buffile:Write()

  local dumpEvery = 30000
  local prevProgress = 0

  local nevt = 0

  local stat_term = MakeSlaveTerm({bgcolor="Grey42", fgcolor="Grey93", fontstyle="Monospace", fontsize=10, geometry="100x15-0+0"})

  print("Convert process started at")
  local success = os.execute("date")

  while fpos < filelength and (max_packet == nil or packet_counter < max_packet) do
    if debug_log == 0 and packet_counter-prevProgress > dumpEvery then
      prevProgress = packet_counter
      local progress = fpos/filelength
      stat_term:Write(string.format("Processed %5.1f %% (%-12i packets)\r", progress*100, packet_counter))
--    io.write("Processed ", (fpos/filelength)*100, " %\r")

      if debug_log == 0 then
        theApp:Update()
      end

--      buffile:Overwrite()
--      buffile:Flush()
    end

    local read_ret, bytes_read = ReadNextPacket(s800_file)
    if read_ret == nil then break end
    packet_counter = packet_counter+1

    if debug_log == 0 and read_ret == "PHYSICS_EVENT" then
--      print(#nscl_buffer)
      nevt = nevt + ProcessNSCLBuffer(nscl_buffer, hists, nevt)
    end

    nscl_buffer = {}
    scaler_buffer = {}

    fpos = s800_file:seek("cur")
  end

  print(string.format("Processed %5.1f %% (%-12i packets)", 100.0, packet_counter))

  print("Convert process finished at")
  success = os.execute("date")

--  buffile:Close()

  return hists
end