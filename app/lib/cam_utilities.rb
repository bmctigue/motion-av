class CamUtilities

  def self.connectionWithMediaType(mediaType, fromConnections:connections)
    for connection in connections
      for port in connection.inputPorts
        return connection if port.mediaType == mediaType
      end
    end
    return nil
  end

end