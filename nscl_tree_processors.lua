require("nscl_unpacker/nscl_unpacker_cfg")

local tbranches, tree

function Initialization(input_type)
  print("setting up TTree")

  tree = TTree("se84", "84Se (d,p)")

  tbranches = {SIDAR = {}, BarrelUp = {}, BarrelDown = {}}

  for i=1,6 do
    tbranches.SIDAR[i] = tree:NewBranch("SIDAR"..tostring(i), "SIDAR_detclass")
  end

  for i=1,12 do
    tbranches.BarrelUp[i] = tree:NewBranch("BarrelUp"..tostring(i), "Barrel_detclass")
  end

  for i=1,12 do
    tbranches.BarrelDown[i] = tree:NewBranch("BarrelDown"..tostring(i), "Barrel_detclass")
  end

  tbranches.IonChamber = tree:NewBranch("IonChamber", "IonChamber_detclass")

  tbranches.CRDC = {}
  tbranches.CRDC[1] = tree:NewBranch("CRDC1", "CRDC_detclass")
  tbranches.CRDC[2] = tree:NewBranch("CRDC2", "CRDC_detclass")

  tbranches.MTDC = tree:NewBranch("MTDC", "MTDC_detclass")

  return tree, tbranches
end

---------------------------------------------------------------
----------------------- PROCESSORS ----------------------------
---------------------------------------------------------------


local CRDCProcessor = {
  anode = function(crdcnum, time)
    tbranches.CRDC[crdcnum]:Get("time"):Set(time)
  end,

  raw = function(crdcnum, pad, en_avg, data)
    tbranches.CRDC[crdcnum]:Get("pads"):PushBack(pad)
    tbranches.CRDC[crdcnum]:Get("raw"):PushBack(data.energies)
    tbranches.CRDC[crdcnum]:Get("sample_nbr"):PushBack(data.samples)
    tbranches.CRDC[crdcnum]:Get("average_raw"):Set(en_avg)
  end,

  cal = function(crdcnum, mult, xgravity)
    tbranches.CRDC[crdcnum]:Get("xgrav"):Set(xgravity)
  end,
}

local ScintProcessor = {
--  up = function(val)
--    online_hists.h_scint_de_up:Fill(val)
--  end,

--  down = function(val)
--    online_hists.h_scint_de_down:Fill(val)
--  end,
}

local IonChamberProcessor = {
--  matrix = function(channel, value)
--    online_hists.h_ic:Fill(channel, value)
--  end,

--  average = function(val)
--    online_hists.h_ic_avg:Fill(val)
--  end,
}

local MTDCProcessor = {
--  matrix = function(channel, value)
--    online_hists.h_mtdc:Fill(channel, value)
--  end,

--  tofs = function(chname, tof)
--    online_hists["h_mtdc_tof_"..chname]:Fill(tof)
--  end,

--  pids = function(hname, tof1, tof2)
--    online_hists[hname]:Fill(tof1, tof2)
--  end
}

local ORRUBAProcessor = function(orruba_data)
--  for k, v in pairs(orruba_monitors) do
--    v.fillfn(v.hist, orruba_data)
--  end
end

local CorrelationProcessor = {
--  ic_vs_xfp = function(tof, ic_en, tof_corr)
--    online_hists.ic_vs_xfp:Fill(tof, ic_en)
--    online_hists.ic_vs_xfp_corr:Fill(tof_corr, ic_en)
--  end,

--  beamangle_vs_xfp = function(tof, angle, cf)
--    online_hists.beamangle_vs_xfp:Fill(tof, angle)
--    online_hists.beamangle_vs_xfp_corr:Fill(tof+angle*cf, angle)
--  end,

--  crdc1x_vs_xfp = function(tof, crdc1x, cf)
--    online_hists.crdc1x_vs_xfp:Fill(tof, crdc1x)
--    online_hists.crdc1x_vs_xfp_corr:Fill(tof+crdc1x*cf, crdc1x)
--  end,

--  h_crdc1_tacvsxgrav = function(x, tac)
--    online_hists.h_crdc1_tacvsxgrav:Fill(x, tac)
--  end,
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
    tree:Fill()
    tree:Reset()
  end)


return Initialization