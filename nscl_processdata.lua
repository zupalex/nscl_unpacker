
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
    beam_angle = 100,
    crdc1x = -0.01,
  }
}

function ProcessNSCLBuffer(nscl_buffer, nevt_origin)
  local gravity_width = 12

  local nevt = 0

  for i, buf in ipairs(nscl_buffer) do
    buf_mem = {}
    local coinc_ORRUBA_S800 = false
    if buf.sourceID == 2+16 then
--          print("Clock difference between ORNL and NSCL DAQ:", v.timestamp2.value - v.timestamp16.value)
      nevt = nevt+1

      local clock_diff = buf.timestamp2.value - buf.timestamp16.value

      online_hists.h_clockdiff:Fill(nevt+nevt_origin, clock_diff)

      if clock_diff < 9 and clock_diff > 3 then
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

        if buf.crdc[j].anode.time then
          NSCL_UNPACKER.CRDCProcessor.anode(crdcid, buf.crdc[j].anode.time)
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

            NSCL_UNPACKER.CRDCProcessor.raw(crdcid, pad, en_avg)

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

        NSCL_UNPACKER.CRDCProcessor.cal(crdcid, mult, xgravity)
      end

      local beam_dif = {
        [1] = buf.crdc[2].xgravity-buf.crdc[1].xgravity,
        [2] = buf.crdc[2].anode.time*cal_params.crdc[2].y_slope + cal_params.crdc[2].y_offset - buf.crdc[1].anode.time*cal_params.crdc[1].y_slope + cal_params.crdc[1].y_offset,
        [3] = cal_params.crdc.gap,
      }

      buf_mem.beam_angle = math.atan(beam_dif[1]/beam_dif[3])

    end

    if buf.scint ~= nil then
      for _s, v in ipairs(buf.scint.up) do
        NSCL_UNPACKER.ScintProcessor.up(v)
      end

      for _s, v in ipairs(buf.scint.down) do
        NSCL_UNPACKER.ScintProcessor.down(v)
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
              NSCL_UNPACKER.MTDCProcessor.matrix(ch, time) 
            end

            if chname and tofs[chname] == nil then
--            if chname and chname ~= "e1up" and chname ~= "e1down" then
              local tof_check = (time - ref) *0.0625
              if mtdc_channels[chname].low_bound < tof_check and mtdc_channels[chname].high_bound > tof_check then
                NSCL_UNPACKER.MTDCProcessor.tofs(chname, tof_check*cal_params.mtdc[chname].slope + cal_params.mtdc[chname].offset)

                tofs[chname] = (time - ref) * 0.0625 
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

    if buf.ionchamber then
      local ic_avg = 0
      for k, v in pairs(buf.ionchamber) do
        ic_avg = ic_avg+v
        NSCL_UNPACKER.IonChamberProcessor.matrix(k, v)
      end

      buf_mem.ic_avg = ic_avg/buf.ionchamber.mult

      NSCL_UNPACKER.IonChamberProcessor.average(buf_mem.ic_avg)
    end

    if buf.orruba then
      NSCL_UNPACKER.ORRUBAProcessor(buf.orruba)

      if coinc_ORRUBA_S800 then
        fillfns.FillChVsValue(online_hists.h_ornl_envsch_s800coinc, buf.orruba)
      end
    end

    if buf_mem.tofs and buf_mem.tofs.xf and buf_mem.ic_avg then
      local corrf = cal_params.tof_correction
      buf_mem.tofs.xf_corr = buf_mem.tofs.xf + buf_mem.beam_angle*corrf.beam_angle + buf_mem.crdc1x*corrf.crdc1x

      NSCL_UNPACKER.CorrelationProcessor.ic_vs_xfp(buf_mem.tofs.xf, buf_mem.ic_avg, buf_mem.tofs.xf_corr)

      NSCL_UNPACKER.CorrelationProcessor.beamangle_vs_xfp(buf_mem.tofs.xf, buf_mem.beam_angle, cal_params.tof_correction.beam_angle)

      NSCL_UNPACKER.CorrelationProcessor.crdc1x_vs_xfp(buf_mem.tofs.xf, buf_mem.crdc1x, cal_params.tof_correction.crdc1x)

      if proton_in_orruba then
        online_hists.h_s800pid_gate_orruba:Fill(buf_mem.tofs.xf_corr, buf_mem.ic_avg)
      end
    end

    proton_in_orruba = false
  end

  return nevt
end