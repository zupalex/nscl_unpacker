
local fillfns = require("ldf_unpacker/ornldaq_monitors")
local mapping = require("ldf_unpacker/se84_mapping")
local calib = require("ldf_unpacker/se84_calibration")

ch_cal, det_cal = calib.readcal()

local can = {}
local online_hists = {}
local active_hists = {}

local _AddMonitor = AddMonitor
function AddMonitor(alias, hparams, fillfn, dest)
  _AddMonitor(alias, hparams, fillfn)

  dest[hparams.name] = orruba_monitors[hparams.name].hist
end

AddSignal("display", function(hname, opts)
    if haliases[hname] then
      haliases[hname].hist:Draw(opts)
      active_hists[hname] = haliases[hname].hist
    elseif online_hists[hname] then
      online_hists[hname]:Draw(opts)
      active_hists[hname] = online_hists[hname]
    end
  end)

AddSignal("display_multi", function(divx, divy, hists)
    local can = TCanvas()
    can:Divide(divx, divy)

    for i, v in ipairs(hists) do
      local row_ = math.floor((i-1)/divy)+1
      local col_ = i - divy*(row_-1)

      if online_hists[hname] then
        can:Draw(online_hists[hname],opts, row_, col_)
        active_hists[hname] = online_hists[hname]
      end

      if haliases[hname] then
        can:Draw(haliases[hname].hist, opts, row_, col_)
        active_hists[hname] = haliases[hname].hist
      elseif online_hists[hname] then
        can:Draw(online_hists[hname], opts, row_, col_)
        active_hists[hname] = online_hists[hname]
      end
    end
  end)

local function checknamematch(name, matches)
  if #matches == 0 then return true end

  for _, m in ipairs(matches) do
    if name:find(m) == nil then
      return false
    end
  end

  return true
end

AddSignal("ls", function(alias, matches, retrieveonly)
    local matching_hists = {}
    if alias == nil or alias then
      for k, v in pairs(haliases) do
        if checknamematch(k, matches) then 
          if not retrieveonly then print(v.type, "\""..tostring(k).."\"") end
          table.insert(matching_hists, k)
        end
      end
    else
      for k, v in pairs(online_hists) do
        if checknamematch(k, matches) then
          if not retrieveonly then print(v.type, "\""..tostring(k).."\"") end
          table.insert(matching_hists, k)
        end
      end
    end

    local result = #matching_hists > 0 and table.concat(matching_hists, "\\li") or "no results"

    SetSharedBuffer(result)
  end)

AddSignal("unmap", function(hname)
    active_hists[hname] = nil
    active_hists[hname] = nil
  end)

local function RegisterHistogram(hists, hname, htitle, nbinsx, xmin, xmax, nbinsy, ymin, ymax)
  local htype
  if nbinsy then
    htype = "2D"
    hists[hname] = TH2(hname, htitle, nbinsx, xmin, xmax, nbinsy, ymin, ymax)
  else
    htype = "1D"
    hists[hname] = TH1(hname, htitle, nbinsx, xmin, xmax)
  end

  haliases[htitle] = {hist=hists[hname], type=htype}
end

function SetupNSCLHistograms()
  local hists = {}

  RegisterHistogram(hists, "h_clockdiff", "Difference between S800 and ORNL measure of ORRUBA Clock (1tick = 100ns) over time", 50000, 0, 5000000, 80, -20, 20)

  RegisterHistogram(hists, "h_crdc1_chs", "CRDC1 Channels", 260, 0, 260)
  RegisterHistogram(hists, "h_crdc1_data", "CRDC1 \"data\"", 10000, 0, 5000)
  RegisterHistogram(hists, "h_crdc1_cal", "CRDC1 \"cal\"", 3000, 0, 300)
  RegisterHistogram(hists, "h_crdc1_mult", "CRDC1 mult", 300, 0, 300)
  RegisterHistogram(hists, "h_crdc1_time", "CRDC1 Anode Time", 4096, 0, 4096)

  RegisterHistogram(hists, "h_crdc1_2d", "CRDC1 energy vs. channel", 300, 0, 300, 8192, 0, 8192)

  RegisterHistogram(hists, "h_crdc2_chs", "CRDC2 Channels", 260, 0, 260)
  RegisterHistogram(hists, "h_crdc2_data", "CRDC2 \"data\"", 10000, 0, 5000)
  RegisterHistogram(hists, "h_crdc2_cal", "CRDC2 \"cal\"", 3000, 0, 300)
  RegisterHistogram(hists, "h_crdc2_mult", "CRDC2 mult", 300, 0, 300)
  RegisterHistogram(hists, "h_crdc2_time", "CRDC2 Anode Time", 4096, 0, 4096)

  RegisterHistogram(hists, "h_crdc2_2d", "CRDC2 energy vs. channel", 300, 0, 300, 8192, 0, 8192)

  RegisterHistogram(hists, "h_scint_de_up", "Scintillator de_up", 8192, 0, 8192)
  RegisterHistogram(hists, "h_scint_de_down", "Scintillator de_down", 8192, 0, 8192)

  RegisterHistogram(hists, "h_mtdc", "Mesytec TDC Time vs. Channel", 32, 0, 32, 65535, 0, 65535)
  RegisterHistogram(hists, "h_mtdc_tof_e1up", "TOF E1 up", 40000, -10000, 70000)
  RegisterHistogram(hists, "h_mtdc_tof_e1down", "TOF E1 down", 40000, -10000, 70000)
  RegisterHistogram(hists, "h_mtdc_tof_xf", "TOF E1 XF", 40000, -10000, 70000)
  RegisterHistogram(hists, "h_mtdc_tof_obj", "TOF E1 OBJ", 40000, -10000, 70000)
  RegisterHistogram(hists, "h_mtdc_tof_gal", "TOF E1 Gallotte", 40000, -10000, 70000)
  RegisterHistogram(hists, "h_mtdc_tof_rf", "TOF E1 RF", 40000, -10000, 70000)
  RegisterHistogram(hists, "h_mtdc_tof_hodo", "TOF E1 Hodoscope", 40000, -10000, 70000)
  RegisterHistogram(hists, "h_tofxf_vs_tofrfxf", "TOF RF - XF vs. TOF XF - E1", 3000, -1000, 2000, 3000, -1000, 2000)

  RegisterHistogram(hists, "h_ic", "Ion Chamber Energy vs. Channel", 16, 0, 16, 4096, 0, 4096)
  RegisterHistogram(hists, "h_ic_avg", "Ion Chamber Average Energy", 4096, 0, 4096)

--------------- ORRUBA HISTOGRAMS ------------------------------

  AddMonitor("ORRUBA En vs. Ch", {name="h_ornl_envsch", title="ORNL DAQ Energy vs. Channel", xmin=0, xmax=700, nbinsx=700, ymin=0, ymax=4096, nbinsy=2048}, fillfns.FillChVsValue, hists)

  for detid=1, 12 do
    for strip=1, 4 do
      local hname = string.format("SX3_U%d_resistive_%d", detid, strip)
      local htitle = string.format("SuperX3 U%d front strip %d", detid, strip)
      local detkey = string.format("SuperX3 U%d", detid)
      AddMonitor(htitle, {name = hname, title = htitle, xmin=0, xmax=4096, nbinsx=512, ymin=0, ymax=4096, nbinsy=512}, fillfns.FillSX3LeftVsRight(detkey, strip), hists)

      hname = string.format("SX3_U%d_position_%d", detid, strip)
      htitle = string.format("SuperX3 U%d position strip %d", detid, strip)
      AddMonitor(htitle, {name = hname, title = htitle, xmin=-1, xmax=1, nbinsx=200, ymin=0, ymax=4096, nbinsy=2048}, fillfns.FillSX3RelativePosition(detkey, strip), hists)

      hname = string.format("SX3_U%d_position_%d_enback", detid, strip)
      htitle = string.format("SuperX3 U%d position strip %d using backside energy", detid, strip)
      AddMonitor(htitle, {name = hname, title = htitle, xmin=-1, xmax=1, nbinsx=200, ymin=0, ymax=4096, nbinsy=2048}, fillfns.FillSX3RelativePosition(detkey, strip, true), hists)

      hname = string.format("SX3_D%d_resistive_%d", detid, strip)
      htitle = string.format("SuperX3 D%d front strip %d", detid, strip)
      detkey = string.format("SuperX3 D%d", detid)
      AddMonitor(htitle, {name = hname, title = htitle, xmin=0, xmax=4096, nbinsx=512, ymin=0, ymax=4096, nbinsy=512}, fillfns.FillSX3LeftVsRight(detkey, strip), hists)

      hname = string.format("SX3_D%d_position_%d", detid, strip)
      htitle = string.format("SuperX3 D%d position strip %d", detid, strip)
      AddMonitor(htitle, {name = hname, title = htitle, xmin=-1, xmax=1, nbinsx=200, ymin=0, ymax=4096, nbinsy=2048}, fillfns.FillSX3RelativePosition(detkey, strip), hists)

      hname = string.format("SX3_D%d_position_%d_enback", detid, strip)
      htitle = string.format("SuperX3 D%d position strip %d using backside energy", detid, strip)
      AddMonitor(htitle, {name = hname, title = htitle, xmin=-1, xmax=1, nbinsx=200, ymin=0, ymax=4096, nbinsy=2048}, fillfns.FillSX3RelativePosition(detkey, strip, true), hists)
    end
  end


  return hists
end

function SetupOfflineCanvas(hists)
  can[1] = TCanvas()
  can[2] = TCanvas()

  for i=1,2 do
    can[i]:Divide(2, 3)
    can[i]:Draw(hists["h_crdc"..tostring(i).."_chs"], "", 1, 1)
    can[i]:Draw(hists["h_crdc"..tostring(i).."_data"], "", 1, 2)
    can[i]:Draw(hists["h_crdc"..tostring(i).."_cal"], "", 1, 3)
    can[i]:Draw(hists["h_crdc"..tostring(i).."_mult"], "", 2, 1)
    can[i]:Draw(hists["h_crdc"..tostring(i).."_time"], "", 2, 2)
    can[i]:Draw(hists["h_crdc"..tostring(i).."_2d"], "colz", 2, 3)
    can[i]:SetLogScale(2, 3, "Z", true)

    can[i]:SetTitle("CRDC"..tostring(i))
    can[i]:SetWindowSize(900, 700)
  end

  can[3] = TCanvas()
  can[3]:Divide(1, 2)

  can[3]:Draw(hists.h_scint_de_up, "", 1, 1)
  can[3]:Draw(hists.h_scint_de_down, "", 1, 2)
  can[3]:SetTitle("Scintillators")
  can[3]:SetWindowSize(600, 400)

  can[4] = TCanvas()
  can[4]:Divide(1, 2)

  can[4]:Draw(hists.h_ic_avg, "", 1, 1)
  can[4]:Draw(hists.h_ic, "colz", 1, 2)
  can[4]:SetLogScale(1, 2, "Z", true)
  can[4]:SetTitle("Ion Chamber")
  can[4]:SetWindowSize(600, 400)

  can[5] = TCanvas()
  can[5]:Divide(3, 3)

  can[5]:Draw(hists.h_mtdc, "colz", 1, 1); can[5]:SetLogScale(1, 1, "Z", true)
  can[5]:Draw(hists.h_mtdc_tof_e1up, "", 1, 2); can[5]:SetLogScale(1, 2, "Y", true)
  can[5]:Draw(hists.h_mtdc_tof_e1down, "", 1, 3); can[5]:SetLogScale(1, 3, "Y", true)
  can[5]:Draw(hists.h_mtdc_tof_xf, "", 2, 1); can[5]:SetLogScale(2, 1, "Y", true)
  can[5]:Draw(hists.h_mtdc_tof_obj, "", 2, 2); can[5]:SetLogScale(2, 2, "Y", true)
  can[5]:Draw(hists.h_mtdc_tof_gal, "", 2, 3); can[5]:SetLogScale(2, 3, "Y", true)
  can[5]:Draw(hists.h_mtdc_tof_rf, "", 3, 1); can[5]:SetLogScale(3, 1, "Y", true)
  can[5]:Draw(hists.h_mtdc_tof_hodo, "", 3, 2); can[5]:SetLogScale(3, 2, "Y", true)
  can[5]:Draw(hists.h_tofrfxf_vs_tofxfe1, "colz", 3, 3); can[5]:SetLogScale(3, 3, "Z", true)
  can[5]:SetTitle("Mesytec TDCs")
  can[5]:SetWindowSize(1100, 900)

  can[6] = TCanvas()
  can[6]:Draw(hists.h_clockdiff, "colz")
end

function UpdateNSCLCanvas()
  for i, v in ipairs(can) do
    v:Update()
  end

  for k, v in pairs(active_hists) do
    v:Update()
  end
end

function InitOfflineDisplay(hists)
  hists.h_clockdiff:Draw("colz")
end

function InitOnlineDisplay(hists)
  online_hists = hists

  hists.h_clockdiff:Draw("colz")
end

function UpdateNSCLHistograms(hists)
  hists.h_clockdiff:Update()

  for k, v in pairs(active_hists) do
    v:Update()
  end
end

local mtdc_channels = {
  e1up = {ch=1},
  e1down = {ch=2},
  xf = {ch=3, low_bound=-50, high_bound=250}, 
  obj = {ch=4, low_bound=-10000, high_bound=70000}, 
  gal = {ch=5, low_bound=-10000, high_bound=70000}, 
  rf = {ch=6, low_bound=-10000, high_bound=70000}, 
  hodo = {ch=13, low_bound=-10000, high_bound=70000}, 
}

function ProcessNSCLBuffer(nscl_buffer, hists, nevt_origin)
  local h1d, h2d = hists, hists

  local gravity_width = 12

  local nevt = 0

  for i, buf in ipairs(nscl_buffer) do
    if buf.sourceID == 2+16 then
--          print("Clock difference between ORNL and NSCL DAQ:", v.timestamp2.value - v.timestamp16.value)
      nevt = nevt+1
      hists.h_clockdiff:Fill(nevt+nevt_origin, buf.timestamp2.value - buf.timestamp16.value)
    end

    if buf.crdc ~= nil then
      for j=1,#buf.crdc do
        if buf.crdc[j].id > 1 then
          print("ERROR: CRDC number is not valid =>", buf.crdc[j].id)
          return
        end

--            print("CRDC ID:", buf.crdc[j].id)
        local hist_base = "h_crdc"..tostring(j).."_"

        if buf.crdc[j].anode.time then
          h1d[hist_base.."time"]:Fill(buf.crdc[j].anode.time)
        end

        for pad, data in pairs(buf.crdc[j].data) do
--              print(buf.crdc[j].channels[m], buf.crdc[j].data[m], buf.crdc[j].sample[m])
          if #data > 0 then
--              if #data > 1 then
            buf.crdc[j].mult = buf.crdc[j].mult+1
            local en_avg = 0

            for sample, val in ipairs(data) do
              en_avg = en_avg + val.energy
            end

--                for sn=1,#data-1 do
--                  en_avg = en_avg + data[sn].energy
--                end

            en_avg = en_avg/#data
--                en_avg = en_avg/(#data-1)


            h1d[hist_base.."chs"]:Fill(pad)
            h1d[hist_base.."data"]:Fill(en_avg)
            h2d[hist_base.."2d"]:Fill(pad, en_avg)

            buf.crdc[j].data[pad] = en_avg
          else
            buf.crdc[j].data[pad] = nil
          end
        end

        local already_checked = {}
        local max_energy = 0
        local max_pad = -1

        for pad, data in pairs(buf.crdc[j].data) do
          if not already_checked[pad] then
            local neighboors = {[-1]=buf.crdc[j].data[pad-1], [1]=buf.crdc[j].data[pad+1]}
            if not neighboors[-1] and not neighboors[1] then
              buf.crdc[j].data[pad] = nil
            elseif neighboors[-1] and neighboors[1] then
              already_checked[pad-1] = true
              already_checked[pad] = true
              already_checked[pad+1] = true

              if max_energy < neighboors[-1] then
                max_energy = neighboors[-1]
                max_pad = pad-1
              end

              if max_energy < neighboors[1] then
                max_energy = data
                max_pad = pad+1
              end

              if max_energy < data then
                max_energy = neighboors[1]
                max_pad = pad
              end
            end
          end
        end

--            print("CRDC max energy", max_energy, "@ pad", max_pad)

        local sum, mom = 0, 0

        if max_pad > -1 then
          local lowpad = math.max(max_pad-gravity_width/2, 0)
          local highpad = math.min(max_pad+gravity_width/2, 256)

          for p = lowpad, highpad do
            local toadd = buf.crdc[j].data[p] and buf.crdc[j].data[p] or 0
            sum = sum + toadd
            mom = mom + p*toadd
          end
        end

        local xgravity = mom / sum

        h1d[hist_base.."mult"]:Fill(buf.crdc[j].mult)
        h1d[hist_base.."cal"]:Fill(xgravity)
      end
    end

    if buf.scint ~= nil then
      for _s, v in ipairs(buf.scint.up) do
        h1d.h_scint_de_up:Fill(v)
      end

      for _s, v in ipairs(buf.scint.down) do
        h1d.h_scint_de_down:Fill(v)
      end
    end

    if buf.mtdc ~= nil then
      local tofs = {}

      local ref = buf.mtdc[1] and buf.mtdc[1][1] or nil

      if ref then
        for ch, hits in pairs(buf.mtdc) do
          local chname

          if ch == mtdc_channels.e1up.ch then chname="e1up"; tofs.e1up = (hits[1] - ref) * 0.0625
          elseif ch == mtdc_channels.e1down.ch then chname="e1down"; tofs.e1down = (hits[1] - ref) * 0.0625
          elseif ch == mtdc_channels.xf.ch then chname = "xf"
          elseif ch == mtdc_channels.obj.ch then chname = "obj"
          elseif ch == mtdc_channels.gal.ch then chname = "gal"
          elseif ch == mtdc_channels.rf.ch then chname = "rf"
          elseif ch == mtdc_channels.hodo.ch then chname = "hodo" end

          for hit, time in ipairs(hits) do
            if hit == 1 then 
              h2d.h_mtdc:Fill(ch, time) 
            end

            if chname and tofs[chname] == nil then
--            if chname and chname ~= "e1up" and chname ~= "e1down" then
              local tof_check = (time - ref) *0.0625
              if mtdc_channels[chname].low_bound < tof_check and mtdc_channels[chname].high_bound > tof_check then
                h1d["h_mtdc_tof_"..chname]:Fill(tof_check)

                tofs[chname] = (time - ref) * 0.0625 
              end
            end
          end

--          if tofs[chname] then
--            h1d["h_mtdc_tof_"..chname]:Fill(tofs[chname])
--          end
        end

        if tofs.xf and tofs.rf then
          hists.h_tofrfxf_vs_tofxfe1:Fill(tofs.rf-tofs.xf, tofs.xf)
        end

      end
    end

    if buf.ionchamber then
      local ic_avg = 0
      for k, v in pairs(buf.ionchamber) do
        ic_avg = ic_avg+v
        h2d.h_ic:Fill(k, v)
      end

      h1d.h_ic_avg:Fill(ic_avg/buf.ionchamber.mult)
    end

    if buf.orruba then
      for k, v in pairs(orruba_monitors) do
        v.fillfn(v.hist, buf.orruba)
      end
    end
  end

  return nevt
end