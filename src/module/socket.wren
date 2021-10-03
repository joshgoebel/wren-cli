import "scheduler" for Scheduler

class Socket {
}

// foreign class TCPServer is Base {
//     construct new(ip, port) {
//             _ip = ip
//             _port = port
//         }
//     listen=(handler) {
//         _handler = handler
//     }
//     serve() {
//         serve_(_ip,_port)
//     }

//     foreign serve_(ip,port)
// }

class TCPServer {
    construct new(ip, port) {
        _ip = ip
        _port = port
        _uv = UVListener.new(ip, port, this)
    }
    onConnect=(fn) {
        _onConnect = fn
    }
    onConnect { _onConnect }
    serve() { _uv.listen_() }
    stop() { _uv.stop_() }
}

class Connection {
    construct new() {
        System.print("new connection")
        _uv = UVConnection.new(this)
        _readBuffer = ""
        _isClosed = false
    }
    isClosed { _isClosed }
    writeLn(data) { _uv.write("%(data)\n") }
    write(data) { _uv.write("%(data)") }
    uv_ { _uv }
    close() { 
        _uv.close() 
        _isClosed = true
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
        if (_readBuffer.isEmpty) {
            _sleepingForRead = Fiber.current
            Scheduler.runNextScheduled_()
        }
        return read()
    }

    // called by C
    input_(data) {
        System.print(("input_"))
        _readBuffer = _readBuffer + data
        if (_sleepingForRead) { 
            var fiber = _sleepingForRead    
            _sleepingForRead = null
            Scheduler.resume_(fiber) 
        }
    }
}

#allocates= uv_tcp_tclient
foreign class UVConnection {
    construct new(connectionWren) {
        System.print("new UVconnection")
    }
    foreign write(str)
    foreign close()
}

foreign class UVListener {
    construct new(ip,port,serverWren) {

    }
    // binds and starts listening
    foreign listen_()
    // stops listening
    foreign stop_()
}