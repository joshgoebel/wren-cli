import "scheduler" for Scheduler

class Lock {
  construct new() { _fiber = null }
  wait() { 
    _fiber = Fiber.current
    Scheduler.runNextScheduled_()
  }
  signal() { 
    if (_fiber == null) return

    var fb = _fiber
    _fiber = null
    Scheduler.resume_(fb) 
  }
  signal(v) { 
    if (_fiber == null) return

    var fb = _fiber
    _fiber = null
    Scheduler.resume_(fb, v) 
  }
}

class TCPServer {
    construct new(ip, port) {
        _ip = ip
        _port = port
        _connections = []
        _uv = UVServer.new(ip, port, this)
        _uv.delegate = this
    }
    #delegated
    newIncomingConnection() {
      var uvconn = UVConnection.new()
      if (_uv.accept(uvconn)) {
        var connection = Connection.new(uvconn)
        _connections.add(connection)
        onConnect.call(connection)
      } else {
        uvconn.close()
      }
    }
    onConnect=(fn) { _onConnect = fn }
    onConnect { _onConnect }
    serve() { _uv.listen_() }
    stop() { _uv.stop_() }
}

class Connection {
    static Open { "open" }
    static Closed { "closed" }

    construct new(uvconn) {
        System.print("new connection")
        _uv = uvconn
        _uv.delegate = this
        _readBuffer = ""
        _readLock = Lock.new()
        _status = Connection.Open
    }
    isClosed { _status == Connection.Closed }
    isOpen { _status == Connection.Open }
    writeLn(data) { _uv.write("%(data)\n") }
    write(data) { _uv.write(data) }
    writeBytes(strData) { _uv.writeBytes(strData) }
    uv_ { _uv }
    close() { 
        _uv.close() 
        _status = Connection.Closed
    }
    // instantly returns the read buffer or null if there is nothing to read
    read() { 
        if (_readBuffer.isEmpty) return null 
        var result = _readBuffer
        _readBuffer = ""
        return result
    }
    // reads data and waits to it if there isn't any
    readWait() {
        if (_readBuffer.isEmpty) waitForData()
        return read()
    }

    buffer_ { _readBuffer }
    seek(bytes) {
      var data 
      if (bytes >= _readBuffer.count) {
        data = _readBuffer
        _readBuffer = ""
      } else {
        data = _readBuffer[0...bytes]
        _readBuffer = _readBuffer[bytes..-1]
      }
      return data
    }
    readLine() {
      var lineSeparator
      while(true) {
        System.print("while loop; buffer %(_readBuffer.bytes.toList)")
        lineSeparator = _readBuffer.indexOf("\n")
        if (lineSeparator != -1) break
        waitForData()
      }
      var line = _readBuffer[0...lineSeparator]
      _readBuffer = _readBuffer[lineSeparator + 1..-1]
      return line
    }

    waitForData() { _readLock.wait() }

    #delegated
    dataReceived(data) {
        if (data==null) { // eof
          _status = Connection.Closed
        } else {
          _readBuffer = _readBuffer + data
        }
        _readLock.signal()
    }
}

foreign class UVConnection {
    construct new() {}
    // delegates must provide:
    // - dataReceived
    static connect(ip, port) {
      connect_(ip,port)
      return Scheduler.runNextScheduled_()
    }
    foreign static connect_(ip, port) 
    foreign delegate=(d)
    foreign writeBytes(strData)
    foreign write(str)
    foreign close()
}

foreign class UVServer {
    construct new(ip,port,serverWren) {}
    foreign accept(client)
    foreign listen_()
    foreign stop_()
    // delegates must provide:
    // - newIncomingConnection
    foreign delegate=(d)
}