NSCL_UNPACKER = {}
NSCL_UNPACKER.sourceIDs = {}

if not NSCL_UNPACKER.NSCL_DAQ_VERSION then NSCL_UNPACKER.NSCL_DAQ_VERSION = 11.0 end
if not NSCL_UNPACKER.PHYSICS_FRAGMENT then NSCL_UNPACKER.PHYSICS_FRAGMENT = true end

debug_log = 0
debug_log_details = {}
ignore_packets = {}


function NSCL_UNPACKER.SetCRDCProcessor(processor)
  NSCL_UNPACKER.CRDCProcessor = processor
end

function NSCL_UNPACKER.SetHodoProcessor(processor)
  NSCL_UNPACKER.HodoProcessor = processor
end

function NSCL_UNPACKER.SetScintProcessor(processor)
  NSCL_UNPACKER.ScintProcessor = processor
end

function NSCL_UNPACKER.SetIonChamberProcessor(processor)
  NSCL_UNPACKER.IonChamberProcessor = processor
end

function NSCL_UNPACKER.SetMTDCProcessor(processor)
  NSCL_UNPACKER.MTDCProcessor = processor
end

function NSCL_UNPACKER.SetTriggerProcessor(processor)
  NSCL_UNPACKER.TriggerProcessor = processor
end

function NSCL_UNPACKER.SetTOFProcessor(processor)
  NSCL_UNPACKER.TOFProcessor = processor
end

function NSCL_UNPACKER.SetORRUBAProcessor(processor)
  NSCL_UNPACKER.ORRUBAProcessor = processor
end

function NSCL_UNPACKER.SetCorrelationProcessor(processor)
  NSCL_UNPACKER.CorrelationProcessor = processor
end

function NSCL_UNPACKER.SetPostProcessing(processor)
  NSCL_UNPACKER.PostProcessing = processor
end