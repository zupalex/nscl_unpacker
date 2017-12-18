require("nscl_unpacker/nscl_unpacker_cfg")
local mapping = require("ldf_unpacker/se84_mapping")

physicsPacketTypes = {}

-- **************** TRIGGER PACKETS ******************** --

local function UnpackTrigger(data, offset, size)
  local last_byte = offset+size
  local trigpattern
  trigpattern, offset = DecodeBytes(data, "H", offset)

--  print(trigpattern)

  if nscl_buffer then
    nscl_buffer[#nscl_buffer].trig = trigpattern
  end

  local trigs = {[8] = "s800", [9] = "external1", [10] = "external2", [11] = "secondary"}

  while offset < last_byte do
    local time, trig

    time, offset = DecodeBytes(data, "H", offset)

    trig = (time & 0xf000) >> 12
  end

  return offset
end

-- **************** TIME OF FLIGHT PACKETS ******************** --

local function UnpackTOF(data, offset, size)
  local last_byte = offset+size

  local tofs = {}

  local tdcs = {[4] = "XFP-FP TAC", [5] = "OBJ-FP TAC", [6] = "TDC A1900 IM1", [7] = "TDC A1900 IM2", [12] = "TDC RF", [13] = "TDC OBJ", [14] = "TDC XFP", [15] = "TDC LaBr"}

  while offset < last_byte do
    local tof, tdc_type

    tof, offset= DecodeBytes(data, "H", offset)

    tdc_type = (tof & 0xf000) >> 12
    tofs[tdcs[tdc_type]] = tof & 0x0fff
  end

  return offset
end

-- **************** TIMESTAMP PACKETS ******************** --

local function UnpackTimestamp(data, offset, size)
  local ts, newoff = DecodeBytes(data, "J", offset)
  if debug_log >= 1 then print("   ##### TIMESTAMP:", ts) end
  return newoff
end

-- **************** EVENT NUMBER PACKETS ******************** --

local function UnpackEventNumber(data, offset, size)
  local evtnb, newoff = DecodeBytes(data, "I6", offset)
  if debug_log >= 1 then print("   ##### EVENT NUMBER:", evtnb) end
  if nscl_buffer then nscl_buffer[#nscl_buffer].evtnbr = evtnb end
  return newoff
end

-- **************** SCIENTILLATOR PACKETS ******************** --

local function UnpackScintillator(data, offset, size)
  local last_byte = offset+size

  if nscl_buffer then
    nscl_buffer[#nscl_buffer].scint = {up = newtable(), down = newtable()}
  end

  while offset < last_byte do
    local en_val, t_val

    en_val, offset = DecodeBytes(data, "H", offset)
    t_val, offset = DecodeBytes(data, "H", offset)

    local ch = (en_val & 0xf000) >> 12

    if debug_log >= 3 and debug_log_details.scint then
      print(ch == 0 and "de_up:" or "de_down:", en_val & 0x07ff, ch == 0 and "time_up:" or "time_down:", t_val & 0x0fff)
    end

    if nscl_buffer then
      nscl_buffer[#nscl_buffer].scint[ch == 0 and "up" or "down"]:insert(en_val & 0x07ff)
    end
  end

  return offset
end

-- **************** ION CHAMBER PACKETS ******************** --

local function UnpackICEnergy(data, offset, size)
  local last_byte = offset+size

  while offset < last_byte do
    local ic_val
    ic_val, offset = DecodeBytes(data, "H", offset)

    local channel = (ic_val & 0xf000) >> 12
    local energy = ic_val & 0x0fff

    if nscl_buffer then
      local icdata = nscl_buffer[#nscl_buffer].ionchamber
      icdata[channel] = energy
      icdata.mult = icdata.mult+1
    end
  end

  return offset
end

local function UnpackIonChamber(data, offset, size)
  local last_byte = offset+size

  local subpacket_length, subpacket_type
  subpacket_length, offset = DecodeBytes(data, "H", offset)
  subpacket_type, offset = DecodeBytes(data, "H", offset)

  if last_byte-offset ~= 2*(subpacket_length-2) then
    logfile:write("We have an issue with Ion Chamber Subpacket @ ", curr_file_pos, " - ", PrintHexa(curr_file_pos), " -\n")
  end

--  print("IC Energy words:", subpacket_length, 2*(subpacket_length-2))

  if nscl_buffer then
    nscl_buffer[#nscl_buffer].ionchamber = {mult=0}
  end

  return physicsPacketTypes[subpacket_type].fn(data, offset, 2*(subpacket_length-2))
end

-- **************** CRDC PACKETS ******************** --

local function UnpackCRDCRaw(data, offset, size)
  local last_byte = offset+size

--  print("CRDC Raw data length received:", datalen)

  local globalThr, ch, sample, badsample

  globalThr, offset = DecodeBytes(data, "H", offset)

  if globalThr > 0 then print("Global Threshold > 0 :", globalThr) end

  local prev_sample, prev_channel

  while offset < last_byte do
    local word, control_bit

    word, offset = DecodeBytes(data, "H", offset)

    control_bit = word >> 15

    if control_bit == 0 and prev_channel == nil then 
      logfile:write("ERROR WHILE READING CRDC PACKET: sample/channel word had wrong control bit @ ", curr_file_pos, " - ", PrintHexa(curr_file_pos)," -\n")
      print("ERROR WHILE READING CRDC PACKET: sample/channel word had wrong control bit @ ", curr_file_pos, " - ", PrintHexa(curr_file_pos))
      break
    elseif control_bit == 1 then
      ch = word & 0x3f
      sample = (word >> 6) & 0x1ff

      if badsample and sample ~= prevsample then
        badsample = false
      end

      prev_sample = nil
      if prev_channel == nil then prev_channel = ch end
    else
      local conn = (word >> 10) & 0x3

      if not bad_sample then
        if nscl_buffer then
          local crdc_entry = nscl_buffer[#nscl_buffer].crdc:back().data
          local pad_num = ch + conn*64

          local energy = word & 0x3ff

          if energy > 0 then
            if crdc_entry[pad_num] == nil then
              crdc_entry[pad_num] = newtable()
--              nscl_buffer[#nscl_buffer].crdc:back().mult = nscl_buffer[#nscl_buffer].crdc:back().mult+1
            end

            crdc_entry[pad_num]:insert({energy=energy, sample=sample})
          end

          if prev_sample == nil then
            prev_sample = sample
          end

          if sample ~= prev_sample then
            if sample ~= prev_sample+1 then
              print("bad sample!", prev_sample, sample)
              crdc_entry[pad_num] = nil
              bad_sample = true
              prev_sample = sample
            else
              prev_sample = sample

              if prev_channel and prev_channel < ch then
                print("Strange ordering here")
              end
            end
          end

          prev_channel = ch
        end

        if (debug_log >= 3 and debug_log_details.crdc) or badsample then
          print("channel:", ch, "connector:", conn, "pad:", ch + conn*64, "data:", energy, "sample:", sample)
        end
      elseif sample ~= prev_sample then
        prev_sample = sample
      end
    end
  end

  return offset
end

local function UnpackCRDCAnode(data, offset, size)
  local en, time

  local crdc_anode = {}
  crdc_anode.energy = {}
  crdc_anode.time = {}

  en, offset = DecodeBytes(data, "H", offset)
  time, offset = DecodeBytes(data, "H", offset)

  if nscl_buffer then
    local crdc_entry = nscl_buffer[#nscl_buffer].crdc:back().anode

    crdc_entry.energy = en & 0xfff
    crdc_entry.time = time & 0xfff
  end
  return offset
end

local function UnpackCRDC(data, offset, size)
  local last_byte = offset+size

--  print("CRDC packet total length:", datalen)

  local label

  label, offset = DecodeBytes(data, "H", offset)

  if debug_log >= 3 and debug_log_details.crdc then
    print("CRDC ID:", label, size)
  end

  if nscl_buffer then
    if nscl_buffer[#nscl_buffer].crdc == nil then 
      nscl_buffer[#nscl_buffer].crdc = newtable() 
    end
    nscl_buffer[#nscl_buffer].crdc:insert({id=label, data={}, anode={}, mult=0})
  end

  local subpacket_length, subpacket_type

  subpacket_length, offset = DecodeBytes(data, "H", offset)
  subpacket_type, offset = DecodeBytes(data, "H", offset)

  if debug_log >= 3 and debug_log_details.crdc then
    print("  -> CRDC Packet:")
    print("     -> First Packet (\"Raw\") =", PrintHexa(subpacket_type,2), subpacket_length)
  end

  offset = physicsPacketTypes[subpacket_type].fn(data, offset, 2*(subpacket_length-2))

  subpacket_length, offset = DecodeBytes(data, "H", offset)
  subpacket_type, offset = DecodeBytes(data, "H", offset)

  if debug_log >= 3 and debug_log_details.crdc then
    print("     -> Second Packet (\"Anode\") =", PrintHexa(subpacket_type, 2), subpacket_length)
  end

  offset = physicsPacketTypes[subpacket_type].fn(data, offset, 2*(subpacket_length-2))

  return offset
end

-- **************** TRACKING PPACs PACKETS ******************** --

local TrackingPPACIndexes = {
  [0]	= { even = 30, odd = 0  },
  [1]	= { even = 31, odd = 1  },
  [2]	= { even = 28, odd = 2  },
  [3]	= { even = 29, odd = 3  },
  [4]	= { even = 26, odd = 4  },
  [5]	= { even = 27, odd = 5  },
  [6]	= { even = 24, odd = 6  },
  [7]	= { even = 25, odd = 7  },
  [8]	= { even = 22, odd = 8  },
  [9]	= { even = 23, odd = 9  },
  [10]	= { even = 20, odd = 10 },
  [11]	= { even = 21, odd = 11 },
  [12]	= { even = 18, odd = 12 },
  [13]	= { even = 19, odd = 13 },
  [14]	= { even = 16, odd = 14 },
  [15]	= { even = 17, odd = 15 },
  [16]	= { even = 14, odd = 16 },
  [17]	= { even = 15, odd = 17 },
  [18]	= { even = 12, odd = 18 },
  [19]	= { even = 13, odd = 19 },
  [20]	= { even = 10, odd = 20 },
  [21]	= { even = 11, odd = 21 },
  [22]	= { even = 8,  odd = 22 },
  [23]	= { even = 9,  odd = 23 },
  [24]	= { even = 6,  odd = 24 },
  [25]	= { even = 7,  odd = 25 },
  [26]	= { even = 4,  odd = 26 },
  [27]	= { even = 5,  odd = 27 },
  [28]	= { even = 2,  odd = 28 },
  [29]	= { even = 3,  odd = 29 },
  [30]	= { even = 0,  odd = 30 },
  [31]	= { even = 1,  odd = 31 },
  [32]	= { even = 33, odd = 63 },
  [33]	= { even = 32, odd = 62 },
  [34]	= { even = 35, odd = 61 },
  [35]	= { even = 34, odd = 60 },
  [36]	= { even = 37, odd = 59 },
  [37]	= { even = 36, odd = 58 },
  [38]	= { even = 39, odd = 57 },
  [39]	= { even = 38, odd = 56 },
  [40]	= { even = 41, odd = 55 },
  [41]	= { even = 40, odd = 54 },
  [42]	= { even = 43, odd = 53 },
  [43]	= { even = 42, odd = 52 },
  [44]	= { even = 45, odd = 51 },
  [45]	= { even = 44, odd = 50 },
  [46]	= { even = 47, odd = 49 },
  [47]	= { even = 46, odd = 48 },
  [48]	= { even = 49, odd = 47 },
  [49]	= { even = 48, odd = 46 },
  [50]	= { even = 51, odd = 45 },
  [51]	= { even = 50, odd = 44 },
  [52]	= { even = 53, odd = 43 },
  [53]	= { even = 52, odd = 42 },
  [54]	= { even = 55, odd = 41 },
  [55]	= { even = 54, odd = 40 },
  [56]	= { even = 57, odd = 39 },
  [57]	= { even = 56, odd = 38 },
  [58]	= { even = 59, odd = 37 },
  [59]	= { even = 58, odd = 36 },
  [60]	= { even = 61, odd = 35 },
  [61]	= { even = 60, odd = 34 },
  [62]	= { even = 63, odd = 33 },
  [63]	= { even = 62, odd = 32 },
}

local function UnpackPpacRaw(data, offset, size)
  local last_byte = offset+size

  local globalThr, ppac_data

  globalThr, offset = DecodeBytes(data, "H", offset)

  while offset < last_byte do
    local word1, word2

    word1, offset = DecodeBytes(data, "H", offset)
    word2, offset = DecodeBytes(data, "H", offset)

    local ch = word1 & 0x3f
    local conn = word2 >> 10

    local idx = (conn%2 == 0) and TrackingPPACIndexes[ch].even or TrackingPPACIndexes[ch].odd
  end

  return offset
end

local function UnpackPpac(data, offset, size)
  local last_byte = offset+size

  local subpacket_length, subpacket_type

  subpacket_length, offset = DecodeBytes(data, "H", offset)
  subpacket_type, offset = DecodeBytes(data, "H", offset)

  return physicsPacketTypes[subpacket_type].fn(data, offset, 2*(subpacket_length-2))
end

-- **************** HODOSCOPE PACKETS ******************** --

local function UnpackHodoEnergy(data, offset, size)
  local last_byte = offset+size

  while offset < last_byte do
    local hodo
    hodo, offset = DecodeBytes(data, "H", offset)
  end

  return offset
end

local function UnpackHodoHitpattern(data, offset, size)
  local hit_0_15, hit_16_31, time

  hit_0_15, offset = DecodeBytes(data, "H", offset)
  hit_16_31, offset = DecodeBytes(data, "H", offset)
  time, offset = DecodeBytes(data, "H", offset)

  return offset
end

local function UnpackHodoscope(data, offset, size)
  local hodo_group

  hodo_group, offset = DecodeBytes(data, "H", offset)

  if hodo_group < 2 then
    return UnpackHodoEnergy(data, offset, size-2)
  else
    return UnpackHodoHitpattern(data, offset, size-2)
  end
end

-- **************** XLM PACKETS (ORRUBA) ******************** --

local function UnpackXLM(data, offset, size)
  local last_byte = offset+size

  local xlm_id, ptag

  local nhits = 0

  while offset < last_byte do
    if xlm_id == nil then
      ptag, offset = DecodeBytes(data, "H", offset)

      if physicsPacketTypes[ptag] and physicsPacketTypes[ptag].subtype == "XLM" then
        if debug_log >= 2 then print("Found", physicsPacketTypes[ptag].name, "packet") end
        if physicsPacketTypes[ptag].name == "XLM1_PACKET" then
          xlm_id = 1
        elseif physicsPacketTypes[ptag].name == "XLM2_PACKET" then
          xlm_id = 2
        else
          print("ERROR in XLM unpack: unknown xlm_id =>", physicsPacketTypes[ptag].name)
        end
      end
    else
      offset = offset + 6

      local nstrips, id, energy, time
      nstrips, offset = DecodeBytes(data, "H", offset)
      offset = offset+8 -- again we skip bytes... no idea what's coded there

      if debug_log >= 2 then print("  -> nstrips:", nstrips, "offset:", offset) end

      for i=1, nstrips do
        id, offset = DecodeBytes(data, "H", offset)
        energy, offset = DecodeBytes(data, "H", offset)
        time, offset = DecodeBytes(data, "H", offset)

        if debug_log >= 2 then 
          print("  ~~~~~~", i, "~~~~~~")
          print("  ------> id / chip / channel:", id, (id & 0x1fe0) >> 5, id & 0x1f)
          print("  ------> energy:", energy)
          print("  ------> time:", time)
          print("  ------> offset:", offset)
        end

        if last_byte - offset < 6 then
          logfile:write("WARNING @ ", curr_file_pos, " - address: ", PrintHexa(curr_file_pos), " - Not enough space remaining in buffer while there should be more strips coming...\n")
          offset = last_byte
          warning_msgs[1].count = warning_msgs[1].count+1
          break
        end
      end

      xlm_id = nil
    end
  end

  return last_byte
end

local function UnpackORRUBA84Se(data, offset, size)
  local last_byte = offset+size

  local orruba_data = {}

  if nscl_buffer then
    nscl_buffer[#nscl_buffer].orruba = {}
  end

  while offset < last_byte do
    local value, channel
    channel, offset = DecodeBytes(data, "H", offset)
    channel = channel & 0x7fff

    value, offset = DecodeBytes(data, "H", offset)

    if nscl_buffer and channel <= 899 then
      nscl_buffer[#nscl_buffer].orruba[channel] = value
    end

    table.insert(orruba_data, {channel=channel, value=value})

    if debug_log >= 2 then 
      print("Channel number:", channel, "Value:", value)
    end
  end

  return last_byte
end

local function UnpackORRUBA84SeV2(data, offset, size)
  local last_byte = offset+size

  local orruba_data = {}

  local buf

  if nscl_buffer then
    nscl_buffer[#nscl_buffer].orruba = {chvalmap = {}}
    buf = nscl_buffer[#nscl_buffer].orruba
  end

  while offset < last_byte do
    local value, channel
    channel, offset = DecodeBytes(data, "H", offset)
    channel = channel & 0x7fff

    value, offset = DecodeBytes(data, "H", offset)

    if buf and channel <= 899 then
      local detinf = mapping.getdetinfo(channel)

      if buf[detinfo.dettype] == nil then
        buf[detinfo.dettype] = {}
      end

      if buf[detinfo.dettype][detinfo.detpos] == nil then
        buf[detinfo.dettype][detinfo.detpos] = {}
      end

      if buf[detinfo.dettype][detinfo.detpos][detinfo.detnum] == nil then
        buf[detinfo.dettype][detinfo.detpos][detinfo.detnum] = {}
      end

      local detbuf = buf[detinfo.dettype][detinfo.detpos][detinfo.detnum]    

      detbuf[detinf.stripnum] = {channel=channel, value=value}
      buf[channel] =  chval
    end

--    table.insert(orruba_data, {channel=channel, value=value})

    if debug_log >= 2 then 
      print("Channel number:", channel, "Value:", value)
    end
  end

  return last_byte
end

-- **************** MESYTEC TDC PACKETS ******************** --

local function UnpackMTDC(data, offset, size)
  local last_byte = offset+size

  local mtdcs

  if nscl_buffer then
    nscl_buffer[#nscl_buffer].mtdc = {}
    mtdcs = nscl_buffer[#nscl_buffer].mtdc
  end

  local hit_word, time, channel, hit

  while offset < last_byte do
    hit_word, offset = DecodeBytes(data, "H", offset)
    time, offset = DecodeBytes(data, "H", offset)

    channel = hit_word & 0xff
    hit = (hit_word >> 8) & 0x1f

    if mtdcs then
      if mtdcs[channel+1] == nil then mtdcs[channel+1] = {} end

      mtdcs[channel+1][hit+1] = time
    end
  end

  return last_byte
end

-- **************** END OF EVENT PACKETS ******************** --

local function DoEndOfEvent(data, offset, size)
  return offset
end

-- **************** LIST OF PHYSICS PACKETS AND THEIR UNPACKING FUNCTIONS ******************** --

physicsPacketTypes = {
  [0x5800] = { name="S800_PACKET", fn = function(data, offset, size)
      local last_byte = offset+size

      local nwords_16, packetTag, s800_version

      nwords_16, offset = DecodeBytes(data, "H", offset) -- for some reasons it is written twice in a row, first in a 32 bits words
      nwords_16, offset = DecodeBytes(data, "H", offset)  -- then in a 16 bits words... Both are self inclusive
      packetTag, offset = DecodeBytes(data, "H", offset)
      s800_version, offset = DecodeBytes(data, "H", offset)

      if debug_log >= 2 then
        print("Number of 16 bits words:", nwords_16)
        print("Packet Tag:", PrintHexa(packetTag, 2), physicsPacketTypes[packetTag].name)
        print("S800 Version:", s800_version)
      end

      while offset < last_byte do
        local length, bytes_length, ptag, pdata
        length, offset = DecodeBytes(data, "H", offset)
        bytes_length = 2*(length-2)

        ptag, offset = DecodeBytes(data, "H", offset)

        if debug_log >= 2 then print("Found packet:", PrintHexa(ptag, 2), physicsPacketTypes[ptag] and physicsPacketTypes[ptag].name or nil, bytes_length) end

        if physicsPacketTypes[ptag].fn then
          offset = physicsPacketTypes[ptag].fn(data, offset, bytes_length)
--          print("offset:", offset)
        else
          pdata = nil
          offset = offset+bytes_length
        end
      end

      return offset
    end},

  [0x5801] = { name="S800_TRIGGER_PACKET", fn = UnpackTrigger},
  [0x5802] = { name="S800_TOF_PACKET",fn = UnpackTOF},
  [0x5803] = { name="S800_TIMESTAMP_PACKET", fn = UnpackTimestamp},
  [0x5804] = { name="S800_EVENT_NUMBER_PACKET", fn = UnpackEventNumber},
  [0x5810] = { name="S800_FP_SCINT_PACKET", fn = UnpackScintillator	},
  [0x5820] = { name="S800_FP_IC_PACKET", fn = UnpackIonChamber},
  [0x5821] = { name="S800_FP_IC_ENERGY_PACKET", fn = UnpackICEnergy},
  [0x5822] = { name="S800_FP_IC_TIME_PACKET", fn = nil},
  [0x5830] = { name="S800_FP_TIME_PACKET", fn = nil},
  [0x5840] = { name="S800_FP_CRDC_PACKET", fn = UnpackCRDC},
  [0x5841] = { name="S800_FP_CRDC_RAW_PACKET", fn = UnpackCRDCRaw},
  [0x5842] = { name="S800_FP_CRDC_SAMPLE_PACKET", fn = nil},
  [0x5843] = { name="S800_FP_CRDC_PAD_PACKET", fn = nil},
  [0x5844] = { name="S800_FP_CRDC_DSP_PACKET", fn = nil},
  [0x5845] = { name="S800_FP_CRDC_ANODE_PACKET", fn = UnpackCRDCAnode},
  [0x5850] = { name="S800_TA_PPAC_PACKET", fn = nil},
  [0xffff] = { name="S800_II_CRDC_PACKET", fn = nil},

  [0x5860] = { name="S800_TA_PIN_PACKET", fn = nil},
  [0x5870] = { name="S800_II_TRACK_PACKET", fn = UnpackPpac},
  [0x5871] = { name="S800_II_TRACK_RAW_PACKET", fn = UnpackPpacRaw},
  [0x5872] = { name="S800_II_TRACK_SAMPLE_PACKET", fn = nil},
  [0x5873] = { name="S800_II_TRACK_PAD_PACKET", fn = nil},
  [0x5874] = { name="S800_II_TRACK_DSP_PACKET", fn = nil},
  [0x5880] = { name="S800_OB_TRACK_PACKET", fn = nil},
  [0x5881] = { name="S800_OB_TRACK_RAW_PACKET", fn = nil},
  [0x5882] = { name="S800_OB_TRACK_SAMPLE_PACKET", fn = nil},
  [0x5883] = { name="S800_OB_TRACK_PAD_PACKET", fn = nil},
  [0x5884] = { name="S800_OB_TRACK_DSP_PACKET", fn = nil},
  [0x5890] = { name="S800_OB_SCINT_PACKET", fn = nil},
  [0x58a0] = { name="S800_OB_PIN_PACKET", fn = nil},
  [0x58b0] = { name="S800_FP_HODO_PACKET", fn = UnpackHodoscope},
  [0x58c0] = { name="S800_VME_ADC_PACKET", fn = nil},
  [0x58d0] = { name="S800_GALOTTE_PACKET", fn = nil},
  [0x58e0] = { name="S800_END_OF_EVENT", fn = DoEndOfEvent},
  [0x58f0] = { name="MESYTEC_TDC_PACKET", fn = UnpackMTDC},

  [0xcccc] = { name="XLM2_PACKET", fn = UnpackXLM, subtype="XLM"},
  [0xaaaa] = { name="XLM1_PACKET", fn = UnpackXLM, subtype="XLM"},

  [0xdabe] = { name = "ORRUBA_84Se_PACKET", fn = UnpackORRUBA84Se}
}