local Identifiers = {
  E16025PacketIdentifier = function(frag_header, data, offset, max_search)
    if frag_header == nil or frag_header.sourceID == 2 then
      ptag = DecodeBytes(data, "H", offset+4)

      if physicsPacketTypes[ptag].name == "S800_PACKET" then
        return ptag
      end
    elseif frag_header and frag_header.sourceID == 16 then
      return 0xdabe
    else
      print("Unknown source ID:", frag_header.sourceID)
    end

    return nil
  end,

  DaveKr86PacketIdentifier = function(frag_header, data, offset, max_search)
    if frag_header == nil or frag_header.sourceID == 1 then
      ptag = DecodeBytes(data, "H", offset+4)

      if physicsPacketTypes[ptag].name == "S800_PACKET" then
        return ptag
      end
    end

    local local_offset, word, last_byte
    local_offset = offset
    last_byte = offset+max_search

    while not (physicsPacketTypes[word] and (physicsPacketTypes[word].subtype == "XLM")) and local_offset < last_byte do
      word, local_offset = DecodeBytes(data, "H", local_offset)
    end
    return local_offset < last_byte and word or nil
  end,
}

return function(override)
  NSCL_UNPACKER.IdentifyPacket = Identifiers[override]
end