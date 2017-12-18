
require("nscl_unpacker/nscl_unpacker_cfg")
local fillfns = require("ldf_unpacker/ornldaq_monitors")
local mapping = require("ldf_unpacker/se84_mapping")
local calib = require("ldf_unpacker/se84_calibration")

ch_cal, det_cal = calib.readcal()

local mtdc_channels = {
  e1up = {ch=1},
  e1down = {ch=2},
  xf = {ch=3, low_bound=-50, high_bound=250},  
  obj = {ch=4, low_bound=-10000, high_bound=70000}, 
  gal = {ch=5, low_bound=-10000, high_bound=70000}, 
  rf = {ch=6, low_bound=-10000, high_bound=70000}, 
  hodo = {ch=13, low_bound=-10000, high_bound=70000}, 
}

local cal_params = {
  crdc = {
    [1] = {x_slope = 2.54, x_offset = -281.94, y_slope = 1, y_offset = 0}, -- the parameters give the final value in mm
    [2] = {x_slope = 2.54, x_offset = -281.94, y_slope = 1, y_offset = 0}, -- the parameters give the final value in mm
    gap = 1073,   -- in mm
  },

  mtdc = {
    e1up = {slope = 1, offset = 0},
    e1down = {slope = 1, offset = 0},
    rf = {slope = 1, offset = 0},
    obj = {slope = 1, offset = 0},
    xf = {slope = 1, offset = 0},
    gal = {slope = 1, offset = 0},
    hodo = {slope = 1, offset = 0},
  },

  tof_correction = {
    beam_angle = 124,
    crdc1x = 0.02,
  }
}

local coinc_window = { -5, 5 }

function SetCoincidenceWindow(clock_min, clock_max)
  coinc_window[1] = clock_min
  coinc_window[2] = clock_max

  print(string.format("Coincidence window between ORRUBA and S800 set to [ %d - %d ]", clock_min, clock_max))
end

AddSignal("setcoincwindow", function(low, high)
    print("setcoincwin", low, high)
    SetCoincidenceWindow(low, high)
  end)

function ProcessNSCLBuffer(nscl_buffer, nevt_origin)
  local gravity_width = 12

  local nevt = 0

  for i, buf in ipairs(nscl_buffer) do
    buf_mem = {}
    coinc_ORRUBA_S800 = false
    have_elastics = false
    have_barrel = false
    validate_SIDAR_protons_nopt = false
    validate_SX3UP_protons_nopt = false
    validate_SX3UP_protons_pt = false
    validate_SX3UP_protons_any = false
    validate_SX3DOWN_protons_nopt = false
    validate_SX3DOWN_protons_pt = false
    validate_SX3DOWN_protons_any = false
    trig_coinc = false

    is_unreacted = false
    is_85se = false
    is_crdcunreacted = false
    is_crdcleftunreac = false

    is_pidtest1 = false
    is_pidtest2 = false
    is_pidtest3 = false
    is_pidtest4 = false
    is_pidtest5 = false


    if buf.trig then
      online_hists.trig_pattern:Fill(buf.trig)

      if buf.trig&2 == 2 then
        trig_coinc = true
      end
    end

    if buf.sourceID == 2+16 and buf.timestamp2 and buf.timestamp2.value and buf.timestamp16 and buf.timestamp16.value then
--          print("Clock difference between ORNL and NSCL DAQ:", v.timestamp2.value - v.timestamp16.value)
      nevt = nevt+1

      local clock_diff = buf.timestamp2.value - buf.timestamp16.value

      online_hists.h_clockdiff:Fill(nevt+nevt_origin, clock_diff)

      if trig_coinc then
        online_hists.h_clockdiff_coinc:Fill(nevt+nevt_origin, clock_diff)
      end

      if clock_diff < coinc_window[2] and clock_diff > coinc_window[1] then
        coinc_ORRUBA_S800 = true
      end
    end

    if buf.crdc ~= nil then
      for j=1,#buf.crdc do
        if buf.crdc[j].id > 1 then
          print("ERROR: CRDC number is not valid =>", buf.crdc[j].id)
          return
        end

        local crdcid = buf.crdc[j].id+1

--        if buf.crdc[j].anode.time then
--          NSCL_UNPACKER.CRDCProcessor.anode(crdcid, buf.crdc[j].anode.time)
--        end

        for pad, data in pairs(buf.crdc[j].data) do
--              print(buf.crdc[j].channels[m], buf.crdc[j].data[m], buf.crdc[j].sample[m])
          if #data > 0 then
            buf.crdc[j].mult = buf.crdc[j].mult+1
            local en_avg = 0

            for sample, val in ipairs(data) do
              en_avg = en_avg + val.energy
            end

            en_avg = en_avg/#data

--            NSCL_UNPACKER.CRDCProcessor.raw(crdcid, pad, en_avg, data)

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

        buf.crdc[j].xgravity = cal_params.crdc[crdcid].x_slope * (mom / sum) + cal_params.crdc[crdcid].x_offset

        buf_mem["crdc"..tostring(j).."x"] = buf.crdc[j].xgravity

--        NSCL_UNPACKER.CRDCProcessor.cal(crdcid, mult, xgravity)
      end

      local beam_dif = {
        [1] = buf.crdc[2].xgravity-buf.crdc[1].xgravity,
        [2] = buf.crdc[2].anode.time*cal_params.crdc[2].y_slope + cal_params.crdc[2].y_offset - buf.crdc[1].anode.time*cal_params.crdc[1].y_slope + cal_params.crdc[1].y_offset,
        [3] = cal_params.crdc.gap,
      }

      buf_mem.beam_angle = math.atan(beam_dif[1]/beam_dif[3])

    end

--    if buf.scint ~= nil then
--      for _s, v in ipairs(buf.scint.up) do
--        NSCL_UNPACKER.ScintProcessor.up(v)
--      end

--      for _s, v in ipairs(buf.scint.down) do
--        NSCL_UNPACKER.ScintProcessor.down(v)
--      end
--    end

    if buf.mtdc ~= nil then
      local tofs = {}

      local ref = buf.mtdc[1] and buf.mtdc[1][1] or nil

      if ref then
        for ch, hits in pairs(buf.mtdc) do
          local chname
          if ch == mtdc_channels.xf.ch then chname = "xf" end

--          if ch == mtdc_channels.e1up.ch then chname="e1up"; tofs.e1up = (hits[1] - ref) * 0.0625
--          elseif ch == mtdc_channels.e1down.ch then chname="e1down"; tofs.e1down = (hits[1] - ref) * 0.0625
--          elseif ch == mtdc_channels.xf.ch then chname = "xf"
--          elseif ch == mtdc_channels.obj.ch then chname = "obj"
--          elseif ch == mtdc_channels.gal.ch then chname = "gal"
--          elseif ch == mtdc_channels.rf.ch then chname = "rf"
--          elseif ch == mtdc_channels.hodo.ch then chname = "hodo" 
--        end

          if chname then
            for hit, time in ipairs(hits) do
              if hit == 1 then 
--                NSCL_UNPACKER.MTDCProcessor.matrix(ch, time) 
              end

              if tofs[chname] == nil then
--            if chname and chname ~= "e1up" and chname ~= "e1down" then
                local tof_check = (time - ref) *0.0625
                if mtdc_channels[chname].low_bound < tof_check and mtdc_channels[chname].high_bound > tof_check then
--                  NSCL_UNPACKER.MTDCProcessor.tofs(chname, tof_check*cal_params.mtdc[chname].slope + cal_params.mtdc[chname].offset)
                  online_hists.h_mtdc_tof_xf:Fill(tof_check*cal_params.mtdc[chname].slope + cal_params.mtdc[chname].offset)

                  tofs[chname] = tof_check
                end
              end
            end
          end

          --          if tofs[chname] then
          --            online_hists["h_mtdc_tof_"..chname]:Fill(tofs[chname])
          --          end
        end

        buf_mem.tofs = tofs

        if tofs.xf and tofs.rf then
          NSCL_UNPACKER.MTDCProcessor.pids("h_tofrfxf_vs_tofxfe1", tofs.rf-tofs.xf, tofs.xf)
        end
      end
    end

    if buf_mem.tofs and buf_mem.tofs.xf and buf_mem.beam_angle and buf_mem.crdc1x then
      local corrf = cal_params.tof_correction
      buf_mem.tofs.xf_corr = buf_mem.tofs.xf + buf_mem.beam_angle*corrf.beam_angle + buf_mem.crdc1x*corrf.crdc1x
    end

    if buf.ionchamber then
      local ic_avg = 0
      for k, v in pairs(buf.ionchamber) do
        ic_avg = ic_avg+v
--        NSCL_UNPACKER.IonChamberProcessor.matrix(k, v)
      end

      buf_mem.ic_avg = ic_avg/buf.ionchamber.mult

----      NSCL_UNPACKER.IonChamberProcessor.average(buf_mem.ic_avg)

      if buf_mem.tofs and buf_mem.tofs.xf then
        local corrf = cal_params.tof_correction

        NSCL_UNPACKER.CorrelationProcessor.ic_vs_xfp(buf_mem.tofs.xf_corr, buf_mem.ic_avg)

        if pid_unreacted and pid_unreacted:IsInside(buf_mem.tofs.xf_corr, buf_mem.ic_avg) == 1 then
          is_unreacted = true
          if buf_mem.crdc1x and buf.crdc[1].anode and buf.crdc[1].anode.time then
            online_hists.h_crdc1_tacvsxgrav_pidunreacted:Fill(buf_mem.crdc1x, buf.crdc[1].anode.time)
          end
        end

        if pid_se85 and pid_se85:IsInside(buf_mem.tofs.xf_corr, buf_mem.ic_avg) == 1 then
          is_85se = true
          if buf_mem.crdc1x and buf.crdc[1].anode and buf.crdc[1].anode.time then
            online_hists.h_crdc1_tacvsxgrav_pid85se:Fill(buf_mem.crdc1x, buf.crdc[1].anode.time)
          end
        end

        if gate_pid_1 and gate_pid_1:IsInside(buf_mem.tofs.xf_corr, buf_mem.ic_avg) == 1 then
          is_pidtest1 = true
          if buf_mem.crdc1x and buf.crdc[1].anode and buf.crdc[1].anode.time then
            online_hists.h_crdc1_tacvsxgrav_pidtest1:Fill(buf_mem.crdc1x, buf.crdc[1].anode.time)
          end
        end

        if gate_pid_2 and gate_pid_2:IsInside(buf_mem.tofs.xf_corr, buf_mem.ic_avg) == 1 then
          is_pidtest2 = true
          if buf_mem.crdc1x and buf.crdc[1].anode and buf.crdc[1].anode.time then
            online_hists.h_crdc1_tacvsxgrav_pidtest2:Fill(buf_mem.crdc1x, buf.crdc[1].anode.time)
          end
        end

        if gate_pid_3 and gate_pid_3:IsInside(buf_mem.tofs.xf_corr, buf_mem.ic_avg) == 1 then
          is_pidtest3 = true
          if buf_mem.crdc1x and buf.crdc[1].anode and buf.crdc[1].anode.time then
            online_hists.h_crdc1_tacvsxgrav_pidtest3:Fill(buf_mem.crdc1x, buf.crdc[1].anode.time)
          end
        end

        if gate_pid_4 and gate_pid_4:IsInside(buf_mem.tofs.xf_corr, buf_mem.ic_avg) == 1 then
          is_pidtest4 = true
          if buf_mem.crdc1x and buf.crdc[1].anode and buf.crdc[1].anode.time then
            online_hists.h_crdc1_tacvsxgrav_pidtest4:Fill(buf_mem.crdc1x, buf.crdc[1].anode.time)
          end
        end

        if gate_pid_5 and gate_pid_5:IsInside(buf_mem.tofs.xf_corr, buf_mem.ic_avg) == 1 then
          is_pidtest5 = true
          if buf_mem.crdc1x and buf.crdc[1].anode and buf.crdc[1].anode.time then
            online_hists.h_crdc1_tacvsxgrav_pidtest5:Fill(buf_mem.crdc1x, buf.crdc[1].anode.time)
          end
        end

        if buf_mem.beam_angle then
          NSCL_UNPACKER.CorrelationProcessor.beamangle_vs_xfp(buf_mem.tofs.xf, buf_mem.beam_angle, cal_params.tof_correction.beam_angle)
        end

        if buf_mem.crdc1x then
          NSCL_UNPACKER.CorrelationProcessor.crdc1x_vs_xfp(buf_mem.tofs.xf, buf_mem.crdc1x, cal_params.tof_correction.crdc1x)
        end

        if crdc_tac_cut:IsInside(buf_mem.crdc1x, buf.crdc[1].anode.time) == 1
        and angle_tof_cut:IsInside(buf_mem.tofs.xf, buf_mem.beam_angle) == 1 then
          NSCL_UNPACKER.CorrelationProcessor.ic_vs_xfp_clean(buf_mem.tofs.xf_corr, buf_mem.ic_avg)
        end
      end
    end

    if buf_mem.crdc1x and buf.crdc[1].anode and buf.crdc[1].anode.time then
      if crdc1x_unreacted and crdc1x_unreacted:IsInside(buf_mem.crdc1x, buf.crdc[1].anode.time) == 1 then
        is_crdcunreacted = true
      end

      if crdc1x_leftunreacted and crdc1x_leftunreacted:IsInside(buf_mem.crdc1x, buf.crdc[1].anode.time) == 1 then
        is_crdcleftunreac = true
      end
    end

    if buf.orruba then
      buf.orruba_cal = {}

      local envsch_hists = { online_hists.h_ornl_envsch }

      if trig_coinc and crdc_tac_cut:IsInside(buf_mem.crdc1x, buf.crdc[1].anode.time) == 1 then
        table.insert(envsch_hists, online_hists.h_ornl_envsch_s800coinc)
      end

      fillfns.CalibrateAndFillChVsValue(envsch_hists, buf.orruba, buf.orruba_cal)

      NSCL_UNPACKER.ORRUBAProcessor(orruba_applycal and buf.orruba_cal or buf.orruba)
    end

    if buf.crdc and buf.crdc[1].anode.time then
      if buf_mem.crdc1x then
        NSCL_UNPACKER.CorrelationProcessor.h_crdc1_tacvsxgrav(buf_mem.crdc1x, buf.crdc[1].anode.time)

        if trig_coinc then
          online_hists.h_crdc1_tacvsxgrav_trigcoinc:Fill(buf_mem.crdc1x, buf.crdc[1].anode.time)
        end

        if validate_SIDAR_protons_nopt or validate_SX3UP_protons_any or validate_SX3DOWN_protons_any then
          online_hists.h_crdc1_tacvsxgrav_gateproton:Fill(buf_mem.crdc1x, buf.crdc[1].anode.time)
        end

        if validate_SIDAR_protons_nopt then
          online_hists.h_crdc1_tacvsxgrav_gatesidar:Fill(buf_mem.crdc1x, buf.crdc[1].anode.time)
        end

        if validate_SX3UP_protons_any then
          online_hists.h_crdc1_tacvsxgrav_gatesx3up:Fill(buf_mem.crdc1x, buf.crdc[1].anode.time)
        end

        if validate_SX3DOWN_protons_any then
          online_hists.h_crdc1_tacvsxgrav_gatesx3down:Fill(buf_mem.crdc1x, buf.crdc[1].anode.time)
        end
      end

      if buf_mem.beam_angle then
        NSCL_UNPACKER.CorrelationProcessor.h_beamangle_vs_tac(buf_mem.beam_angle, buf.crdc[1].anode.time)
      end
    end

    if buf_mem.tofs and buf_mem.tofs.xf and buf_mem.ic_avg then
      if trig_coinc then
        online_hists.h_s800pid_gate_orruba:Fill(buf_mem.tofs.xf_corr, buf_mem.ic_avg)
      end

      if have_elastics then
        online_hists.h_s800pid_gate_orruba_elastics:Fill(buf_mem.tofs.xf_corr, buf_mem.ic_avg)
      end

      if have_barrel then
        online_hists.h_s800pid_gate_orruba_barrel:Fill(buf_mem.tofs.xf_corr, buf_mem.ic_avg)
      end

      if validate_SIDAR_protons_nopt then
        online_hists.ic_vs_xfp_gate_sidar_protons_nopt:Fill(buf_mem.tofs.xf_corr, buf_mem.ic_avg)
      end

      if validate_SX3UP_protons_nopt then
        online_hists.ic_vs_xfp_gate_sx3up_protons_nopt:Fill(buf_mem.tofs.xf_corr, buf_mem.ic_avg)
      end

      if validate_SX3UP_protons_pt then
        online_hists.ic_vs_xfp_gate_sx3up_protons_pt:Fill(buf_mem.tofs.xf_corr, buf_mem.ic_avg)
      end

      if validate_SX3UP_protons_any then
        online_hists.ic_vs_xfp_gate_sx3up_protons_any:Fill(buf_mem.tofs.xf_corr, buf_mem.ic_avg)
      end

      if validate_SX3DOWN_protons_nopt then
        online_hists.ic_vs_xfp_gate_sx3down_protons_nopt:Fill(buf_mem.tofs.xf_corr, buf_mem.ic_avg)
      end

      if validate_SX3DOWN_protons_pt then
        online_hists.ic_vs_xfp_gate_sx3down_protons_pt:Fill(buf_mem.tofs.xf_corr, buf_mem.ic_avg)
      end

      if validate_SX3DOWN_protons_any then
        online_hists.ic_vs_xfp_gate_sx3down_protons_any:Fill(buf_mem.tofs.xf_corr, buf_mem.ic_avg)
      end
    end
  end

  return nevt
end