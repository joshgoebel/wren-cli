import "socket" for TCPServer
import "timer" for Timer

var server = TCPServer.new("0.0.0.0",7000)
server.onConnect = Fn.new() { |connection|
    connection.writeLn("Hello, bob")
    connection.close()
}
server.serve()
Timer.sleep(10000)
System.print("stopping...")
server.stop()

Timer.sleep(10000)
System.print("serving...")
server.serve()
// server.stop()

// server = null
// System.gc()