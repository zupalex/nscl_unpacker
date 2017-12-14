require("nscl_unpacker/nscl_unpacker_cfg")
fillfns = require("ldf_unpacker/ornldaq_monitors")

local can = {}
online_hists = {}
local active_hists = {}

local _AddMonitor = AddMonitor
function AddMonitor(alias, hparams, fillfn)
  _AddMonitor(alias, hparams, fillfn)

  online_hists[hparams.name] = orruba_monitors[hparams.name].hist
end

local function RegisterHistogram(hname, htitle, nbinsx, xmin, xmax, nbinsy, ymin, ymax)
  local htype
  if nbinsy then
    htype = "2D"
    online_hists[hname] = TH2(hname, htitle, nbinsx, xmin, xmax, nbinsy, ymin, ymax)
  else
    htype = "1D"
    online_hists[hname] = TH1(hname, htitle, nbinsx, xmin, xmax)
  end

  haliases[htitle] = {hist=online_hists[hname], type=htype}
end

function SetupNSCLHistograms()
  RegisterHistogram("h_clockdiff", "Difference between S800 and ORNL measure of ORRUBA Clock (1tick = 100ns) over time", 50000, 0, 5000000, 80, -20, 20)

  RegisterHistogram("h_crdc1_chs", "CRDC1 Channels", 260, 0, 260)
  RegisterHistogram("h_crdc1_data", "CRDC1 data", 10000, 0, 5000)
  RegisterHistogram("h_crdc1_cal", "CRDC1 cal", 3000, 0, 300)
  RegisterHistogram("h_crdc1_mult", "CRDC1 mult", 300, 0, 300)
  RegisterHistogram("h_crdc1_time", "CRDC1 Anode Time", 4096, 0, 4096)

  RegisterHistogram("h_crdc1_2d", "CRDC1 energy vs. channel", 300, 0, 300, 8192, 0, 8192)

  RegisterHistogram("h_crdc2_chs", "CRDC2 Channels", 260, 0, 260)
  RegisterHistogram("h_crdc2_data", "CRDC2 data", 10000, 0, 5000)
  RegisterHistogram("h_crdc2_cal", "CRDC2 cal", 3000, 0, 300)
  RegisterHistogram("h_crdc2_mult", "CRDC2 mult", 300, 0, 300)
  RegisterHistogram("h_crdc2_time", "CRDC2 Anode Time", 4096, 0, 4096)

  RegisterHistogram("h_crdc2_2d", "CRDC2 energy vs. channel", 300, 0, 300, 8192, 0, 8192)

  RegisterHistogram("h_scint_de_up", "Scintillator de_up", 8192, 0, 8192)
  RegisterHistogram("h_scint_de_down", "Scintillator de_down", 8192, 0, 8192)

  RegisterHistogram("h_mtdc", "Mesytec TDC Time vs. Channel", 32, 0, 32, 65535, 0, 65535)
  RegisterHistogram("h_mtdc_tof_e1up", "TOF E1 up", 2000, -300, 700)
  RegisterHistogram("h_mtdc_tof_e1down", "TOF E1 down", 2000, -300, 700)
  RegisterHistogram("h_mtdc_tof_xf", "TOF E1 XF", 5000, -1000, 4000)
  RegisterHistogram("h_mtdc_tof_obj", "TOF E1 OBJ", 2000, -300, 700)
  RegisterHistogram("h_mtdc_tof_gal", "TOF E1 Gallotte", 2000, -300, 700)
  RegisterHistogram("h_mtdc_tof_rf", "TOF E1 RF", 2000, -300, 700)
  RegisterHistogram("h_mtdc_tof_hodo", "TOF E1 Hodoscope", 2000, -300, 700)
  RegisterHistogram("h_tofrfxf_vs_tofxfe1", "TOF RF - XF vs. TOF XF - E1", 2000, -300, 700, 2000, -300, 700)

  RegisterHistogram("h_ic", "Ion Chamber Energy vs. Channel", 16, 0, 16, 4096, 0, 4096)
  RegisterHistogram("h_ic_avg", "Ion Chamber Average Energy", 4096, 0, 4096)

  RegisterHistogram("ic_vs_xfp", "Ion Chamber Avergage Energy vs. TOF XF - E1", 2000, -300, 700, 2048, 0, 4096)
  RegisterHistogram("ic_vs_xfp_corr", "Ion Chamber Avergage Energy vs. Corrected TOF XF - E1", 2000, -300, 700, 2048, 0, 4096)

  RegisterHistogram("beamangle_vs_xfp", "Beam Angle (rad) vs. TOF XF - E1", 2000, -300, 700, 4000, -1, 1)
  RegisterHistogram("beamangle_vs_xfp_corr", "Beam Angle (rad) vs. Corrected TOF XF - E1", 1600, -100, 300, 1600, -0.1, 0.1)

  RegisterHistogram("crdc1x_vs_xfp", "CRDC 1 X vs. TOF XF - E1", 2000, -300, 700, 2000, -100, 100)
  RegisterHistogram("crdc1x_vs_xfp_corr", "CRDC 1 X vs. Corrected TOF XF - E1", 1600, -100, 300, 2000, -100, 100)

  RegisterHistogram("h_ornl_envsch_s800coinc", "ORRUBA Energy vs. Channel - S800 coincidence", 899, 0, 899, 2048, 0, 4096)

  RegisterHistogram("h_s800pid_gate_orruba", "(Gate ORRUBA) Ion Chamber Avergage Energy vs. Corrected TOF XF - E1", 2000, -300, 700, 2048, 0, 4096)
end

function SetupORRUBAHistograms()
  if not orruba_applycal then
    AddMonitor("ORRUBA En vs. Ch", {name="h_ornl_envsch", title="ORNL DAQ Energy vs. Channel", xmin=0, xmax=899, nbinsx=899, ymin=0, ymax=4096, nbinsy=2048}, fillfns.FillChVsValue)
  else
    AddMonitor("ORRUBA En vs. Ch", {name="h_ornl_envsch", title="ORNL DAQ Energy vs. Channel", xmin=0, xmax=899, nbinsx=899, ymin=0, ymax=10, nbinsy=1000}, fillfns.FillChVsValue)
  end

--    AddMonitor("ORRUBA En vs. Ch - S800 coincidence", {name="h_ornl_envsch_s800coinc", title="ORNL DAQ Energy vs. Channel - S800 coincidence", xmin=0, xmax=899, nbinsx=899, ymin=0, ymax=4096, nbinsy=2048}, fillfns.FillChVsValue)

  for detid=1, 12 do
    for strip=1, 4 do
      local hname = string.format("SX3_U%d_resistive_%d", detid, strip)
      local htitle = string.format("SuperX3 U%d front strip %d", detid, strip)
      local detkey = string.format("SuperX3 U%d", detid)
      AddMonitor(htitle, {name = hname, title = htitle, xmin=0, xmax=4096, nbinsx=512, ymin=0, ymax=4096, nbinsy=512}, fillfns.FillSX3LeftVsRight(detkey, strip))

      hname = string.format("SX3_U%d_position_%d", detid, strip)
      htitle = string.format("SuperX3 U%d Energy vs Position strip %d", detid, strip)
      AddMonitor(htitle, {name = hname, title = htitle, xmin=-1, xmax=1, nbinsx=200, ymin=0, ymax=4096, nbinsy=2048}, fillfns.FillSX3EnergyVsPosition(detkey, strip))

      hname = string.format("SX3_U%d_position_%d_enback", detid, strip)
      htitle = string.format("SuperX3 U%d Energy vs Position %d using backside energy", detid, strip)
      AddMonitor(htitle, {name = hname, title = htitle, xmin=-1, xmax=1, nbinsx=200, ymin=0, ymax=4096, nbinsy=2048}, fillfns.FillSX3EnergyVsPosition(detkey, strip, true))

      hname = string.format("SX3_D%d_resistive_%d", detid, strip)
      htitle = string.format("SuperX3 D%d front strip %d", detid, strip)
      detkey = string.format("SuperX3 D%d", detid)
      AddMonitor(htitle, {name = hname, title = htitle, xmin=0, xmax=4096, nbinsx=512, ymin=0, ymax=4096, nbinsy=512}, fillfns.FillSX3LeftVsRight(detkey, strip))

      hname = string.format("SX3_D%d_position_%d", detid, strip)
      htitle = string.format("SuperX3 D%d Energy vs Position strip %d", detid, strip)
      AddMonitor(htitle, {name = hname, title = htitle, xmin=-1, xmax=1, nbinsx=200, ymin=0, ymax=4096, nbinsy=2048}, fillfns.FillSX3EnergyVsPosition(detkey, strip))

      hname = string.format("SX3_D%d_position_%d_enback", detid, strip)
      htitle = string.format("SuperX3 D%d Energy vs Position strip %d using backside energy", detid, strip)
      AddMonitor(htitle, {name = hname, title = htitle, xmin=-1, xmax=1, nbinsx=200, ymin=0, ymax=4096, nbinsy=2048}, fillfns.FillSX3EnergyVsPosition(detkey, strip, true))
    end
  end

  for strip=1,4 do
    hname = string.format("Elastics_TR_%d", strip)
    htitle = string.format("Elastics Top Right Energy vs Position strip %d", strip)
    AddMonitor(htitle, {name = hname, title = htitle, xmin=-1, xmax=1, nbinsx=200, ymin=0, ymax=4096, nbinsy=2048}, fillfns.FillSX3EnergyVsPosition("Elastics TOP_RIGHT", strip))

--    hname = string.format("Elastics_TR_%d_back", strip)
--    htitle = string.format("Elastics Top Right Energy vs Position strip %d using backside", strip)
--    AddMonitor(htitle, {name = hname, title = htitle, xmin=-1, xmax=1, nbinsx=200, ymin=0, ymax=4096, nbinsy=2048}, fillfns.FillSX3EnergyVsPosition("Elastics TOP_RIGHT", strip, true))

    hname = string.format("Elastics_BR_%d", strip)
    htitle = string.format("Elastics Bottom Right Energy vs Position strip %d", strip)
    AddMonitor(htitle, {name = hname, title = htitle, xmin=-1, xmax=1, nbinsx=200, ymin=0, ymax=4096, nbinsy=2048}, fillfns.FillSX3EnergyVsPosition("Elastics BOTTOM_RIGHT", strip))

--    hname = string.format("Elastics_BR_%d_back", strip)
--    htitle = string.format("Elastics Bottom Right Energy vs Position strip %d using backside", strip)
--    AddMonitor(htitle, {name = hname, title = htitle, xmin=-1, xmax=1, nbinsx=200, ymin=0, ymax=4096, nbinsy=2048}, fillfns.FillSX3EnergyVsPosition("Elastics BOTTOM_RIGHT", strip, true))

    hname = string.format("Elastics_BL_%d", strip)
    htitle = string.format("Elastics Bottom Left Energy vs Position strip %d", strip)
    AddMonitor(htitle, {name = hname, title = htitle, xmin=-1, xmax=1, nbinsx=200, ymin=0, ymax=4096, nbinsy=2048}, fillfns.FillSX3EnergyVsPosition("Elastics BOTTOM_LEFT", strip))

--    hname = string.format("Elastics_BL_%d_back", strip)
--    htitle = string.format("Elastics Bottom Left Energy vs Position strip %d using backside", strip)
--    AddMonitor(htitle, {name = hname, title = htitle, xmin=-1, xmax=1, nbinsx=200, ymin=0, ymax=4096, nbinsy=2048}, fillfns.FillSX3EnergyVsPosition("Elastics BOTTOM_LEFT", strip, true))
  end

  AddMonitor("MCP1 X MPD4", {name = "MCP1_X_MPD4", title = "MCP1 X Position MPD4", xmin = 0, xmax = 1024, nbinsx = 512}, fillfns.FillMCP("MCP 1 MPD4", "x"))
  AddMonitor("MCP1 Y MPD4", {name = "MCP1_Y_MPD4", title = "MCP1 Y Position MPD4", xmin = 0, xmax = 1024, nbinsx = 512}, fillfns.FillMCP("MCP 1 MPD4", "y"))
  AddMonitor("MCP2 X MPD4", {name = "MCP2_X_MPD4", title = "MCP2 X Position MPD4", xmin = 0, xmax = 4096, nbinsx = 2048}, fillfns.FillMCP("MCP 2 MPD4", "x"))
  AddMonitor("MCP2 Y MPD4", {name = "MCP2_Y_MPD4", title = "MCP2 Y Position MPD4", xmin = 0, xmax = 4096, nbinsx = 2048}, fillfns.FillMCP("MCP 2 MPD4", "y"))

  AddMonitor("MCP1 X vs. Y MPD4", {name = "MCP1_XvsY_MDB4", title = "MCP1 X vs. Y MPD4", xmin = -1, xmax = 1, nbinsx = 1500, ymin = -1, ymax = 1, nbinsy = 1500}, fillfns.FillMCP("MCP 1 MPD4", "x vs. y"))
  AddMonitor("MCP2 X vs. Y MPD4", {name = "MCP2_XvsY_MDB4", title = "MCP2 X vs. Y MPD4", xmin = -1, xmax = 1, nbinsx = 1000, ymin = -1, ymax = 1, nbinsy = 1000}, fillfns.FillMCP("MCP 2 MPD4", "x vs. y"))

  AddMonitor("MCP1 X QDC", {name = "MCP1_X_QDC", title = "MCP1 X Position with QDC", xmin = 0, xmax = 1024, nbinsx = 512}, fillfns.FillMCP("MCP 1 QDC", "x"))
  AddMonitor("MCP1 Y QDC", {name = "MCP1_Y_QDC", title = "MCP1 Y Position with QDC", xmin = 0, xmax = 1024, nbinsx = 512}, fillfns.FillMCP("MCP 1 QDC", "y"))
  AddMonitor("MCP2 X QDC", {name = "MCP2_X_QDC", title = "MCP2 X Position with QDC", xmin = 0, xmax = 4096, nbinsx = 2048}, fillfns.FillMCP("MCP 2 QDC", "x"))
  AddMonitor("MCP2 Y QDC", {name = "MCP2_Y_QDC", title = "MCP2 Y Position with QDC", xmin = 0, xmax = 4096, nbinsx = 2048}, fillfns.FillMCP("MCP 2 QDC", "y"))

  AddMonitor("MCP1 X vs. Y QDC", {name = "MCP1_XvsY_QDC", title = "MCP1 X vs. Y with QDC", xmin = -1, xmax = 1, nbinsx = 1500, ymin = -1, ymax = 1, nbinsy = 1500}, fillfns.FillMCP("MCP 1 QDC", "x vs. y"))
  AddMonitor("MCP2 X vs. Y QDC", {name = "MCP2_XvsY_QDC", title = "MCP2 X vs. Y with QDC", xmin = -1, xmax = 1, nbinsx = 1000, ymin = -1, ymax = 1, nbinsy = 1000}, fillfns.FillMCP("MCP 2 QDC", "x vs. y"))
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

    for i, hname in ipairs(hists) do
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

function SetupOfflineCanvas()
  can[1] = TCanvas()
  can[2] = TCanvas()

  for i=1,2 do
    can[i]:Divide(2, 3)
    can[i]:Draw(online_hists["h_crdc"..tostring(i).."_chs"], "", 1, 1)
    can[i]:Draw(online_hists["h_crdc"..tostring(i).."_data"], "", 1, 2)
    can[i]:Draw(online_hists["h_crdc"..tostring(i).."_cal"], "", 1, 3)
    can[i]:Draw(online_hists["h_crdc"..tostring(i).."_mult"], "", 2, 1)
    can[i]:Draw(online_hists["h_crdc"..tostring(i).."_time"], "", 2, 2)
    can[i]:Draw(online_hists["h_crdc"..tostring(i).."_2d"], "colz", 2, 3)
    can[i]:SetLogScale(2, 3, "Z", true)

    can[i]:SetTitle("CRDC"..tostring(i))
    can[i]:SetWindowSize(900, 700)
  end

  can[3] = TCanvas()
  can[3]:Divide(1, 2)

  can[3]:Draw(online_hists.h_scint_de_up, "", 1, 1)
  can[3]:Draw(online_hists.h_scint_de_down, "", 1, 2)
  can[3]:SetTitle("Scintillators")
  can[3]:SetWindowSize(600, 400)

  can[4] = TCanvas()
  can[4]:Divide(1, 2)

  can[4]:Draw(online_hists.h_ic_avg, "", 1, 1)
  can[4]:Draw(online_hists.h_ic, "colz", 1, 2)
  can[4]:SetLogScale(1, 2, "Z", true)
  can[4]:SetTitle("Ion Chamber")
  can[4]:SetWindowSize(600, 400)

  can[5] = TCanvas()
  can[5]:Divide(3, 3)

  can[5]:Draw(online_hists.h_mtdc, "colz", 1, 1); can[5]:SetLogScale(1, 1, "Z", true)
  can[5]:Draw(online_hists.h_mtdc_tof_e1up, "", 1, 2); can[5]:SetLogScale(1, 2, "Y", true)
  can[5]:Draw(online_hists.h_mtdc_tof_e1down, "", 1, 3); can[5]:SetLogScale(1, 3, "Y", true)
  can[5]:Draw(online_hists.h_mtdc_tof_xf, "", 2, 1); can[5]:SetLogScale(2, 1, "Y", true)
  can[5]:Draw(online_hists.h_mtdc_tof_obj, "", 2, 2); can[5]:SetLogScale(2, 2, "Y", true)
  can[5]:Draw(online_hists.h_mtdc_tof_gal, "", 2, 3); can[5]:SetLogScale(2, 3, "Y", true)
  can[5]:Draw(online_hists.h_mtdc_tof_rf, "", 3, 1); can[5]:SetLogScale(3, 1, "Y", true)
  can[5]:Draw(online_hists.h_mtdc_tof_hodo, "", 3, 2); can[5]:SetLogScale(3, 2, "Y", true)
  can[5]:Draw(online_hists.h_tofrfxf_vs_tofxfe1, "colz", 3, 3); can[5]:SetLogScale(3, 3, "Z", true)
  can[5]:SetTitle("Mesytec TDCs")
  can[5]:SetWindowSize(1100, 900)

  can[6] = TCanvas()
  can[6]:Draw(online_hists.h_clockdiff, "colz")
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

function InitOnlineDisplay()
  online_hists.h_clockdiff:Draw("colz")
end

function UpdateNSCLHistograms()
  online_hists.h_clockdiff:Update()

  for k, v in pairs(active_hists) do
    v:Update()
  end
end

function Initialization(input_type)
  SetupNSCLHistograms()
  SetupORRUBAHistograms()

  if input_type:lower() == "online" then
    InitOnlineDisplay()
  elseif input_type:lower() == "file" then
    SetupOfflineCanvas(hists)
  end
end

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

---------------------------------------------------------------
----------------------- PROCESSORS ----------------------------
---------------------------------------------------------------


local CRDCProcessor = {
  anode = function(crdcnum, time)
    online_hists["h_crdc"..tostring(crdcnum).."_time"]:Fill(time)
  end,

  raw = function(crdcnum, pad, en_avg)
    online_hists["h_crdc"..tostring(crdcnum).."_chs"]:Fill(pad)
    online_hists["h_crdc"..tostring(crdcnum).."_data"]:Fill(en_avg)
    online_hists["h_crdc"..tostring(crdcnum).."_2d"]:Fill(pad, en_avg)
  end,

  cal = function(crdcnum, mult, xgravity)
    online_hists["h_crdc"..tostring(crdcnum).."_mult"]:Fill(mult)
    online_hists["h_crdc"..tostring(crdcnum).."_cal"]:Fill(xgravity)
  end,
}

local ScintProcessor = {
  up = function(val)
    online_hists.h_scint_de_up:Fill(val)
  end,

  down = function(val)
    online_hists.h_scint_de_down:Fill(val)
  end,
}

local IonChamberProcessor = {
  matrix = function(channel, value)
    online_hists.h_ic:Fill(channel, value)
  end,

  average = function(val)
    online_hists.h_ic_avg:Fill(val)
  end,
}

local MTDCProcessor = {
  matrix = function(channel, value)
    online_hists.h_mtdc:Fill(channel, value)
  end,

  tofs = function(chname, tof)
    online_hists["h_mtdc_tof_"..chname]:Fill(tof)
  end,

  pids = function(hname, tof1, tof2)
    online_hists[hname]:Fill(tof1, tof2)
  end
}

local ORRUBAProcessor = function(orruba_data)
  for k, v in pairs(orruba_monitors) do
    v.fillfn(v.hist, orruba_data)
  end
end

local CorrelationProcessor = {
  ic_vs_xfp = function(tof, ic_en, tof_corr)
    online_hists.ic_vs_xfp:Fill(tof, ic_en)
    online_hists.ic_vs_xfp_corr:Fill(tof_corr, ic_en)
  end,

  beamangle_vs_xfp = function(tof, angle, cf)
    online_hists.beamangle_vs_xfp:Fill(tof, angle)
    online_hists.beamangle_vs_xfp_corr:Fill(tof+angle*cf, angle)
  end,

  crdc1x_vs_xfp = function(tof, crdc1x, cf)
    online_hists.crdc1x_vs_xfp:Fill(tof, crdc1x)
    online_hists.crdc1x_vs_xfp_corr:Fill(tof+crdc1x*cf, crdc1x)
  end,
}

NSCL_UNPACKER.SetCRDCProcessor(CRDCProcessor)
--NSCL_UNPACKER.SetHodoProcessor()
NSCL_UNPACKER.SetScintProcessor(ScintProcessor)
NSCL_UNPACKER.SetIonChamberProcessor(IonChamberProcessor)
NSCL_UNPACKER.SetMTDCProcessor(MTDCProcessor)
--NSCL_UNPACKER.SetTriggerProcessor()
--NSCL_UNPACKER.SetTOFProcessor()
NSCL_UNPACKER.SetORRUBAProcessor(ORRUBAProcessor)

NSCL_UNPACKER.SetCorrelationProcessor(CorrelationProcessor)

NSCL_UNPACKER.SetPostProcessing(function()
    UpdateNSCLHistograms()
  end)


return Initialization