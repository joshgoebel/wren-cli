#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <uv.h>
#include "../cli/vm.h"
#include "socket.h"

uv_loop_t *loop;
struct sockaddr_in addr;


void alloc_buffer(uv_handle_t *handle, size_t suggested_size, uv_buf_t *buf) {
    buf->base = (char*)malloc(suggested_size);
    buf->len = suggested_size;
}

void echo_write(uv_write_t *req, int status) {
    if (status) {
        fprintf(stderr, "Write error %s\n", uv_strerror(status));
    }
    free(req);
}

void echo_read(uv_stream_t *client, ssize_t nread, const uv_buf_t *buf) {
    if (nread < 0) {
        if (nread != UV_EOF) {
            fprintf(stderr, "Read error %s\n", uv_err_name(nread));
            uv_close((uv_handle_t*) client, NULL);
        }
    } else if (nread > 0) {
        uv_write_t *req = (uv_write_t *) malloc(sizeof(uv_write_t));
        uv_buf_t wrbuf = uv_buf_init(buf->base, nread);
        uv_write(req, client, &wrbuf, 1, echo_write);
    }

    if (buf->base) {
        free(buf->base);
    }
}

void on_new_connection(uv_stream_t *server, int status) {
    if (status < 0) {
        fprintf(stderr, "New connection error %s\n", uv_strerror(status));
        return;
    }

    uv_tcp_t *client = (uv_tcp_t*)malloc(sizeof(uv_tcp_t));
    uv_tcp_init(getLoop(), client);
    if (uv_accept(server, (uv_stream_t*) client) == 0) {
        uv_read_start((uv_stream_t*)client, alloc_buffer, echo_read);
    } else {
        uv_close((uv_handle_t*) client, NULL);
    }
}

void tcpServerAllocate(WrenVM* vm) {
    fprintf(stdout, "alloc\n");
    fflush(0);
}

void tcpServerFinalize(WrenVM* vm) {
    fprintf(stdout, "finalized\n");
    fflush(0);
}

void tcpServerServe(WrenVM* vm) {

    const char* address = wrenGetSlotString(vm, 1);
    const double port = wrenGetSlotDouble(vm, 2);

    tcp_server_t* tcpServer = (tcp_server_t*)malloc(sizeof(tcp_server_t));
    memset(tcpServer, 0, sizeof(tcp_server_t));

    uv_tcp_init(getLoop(), &tcpServer->server);
    uv_ip4_addr(address, port, &tcpServer->addr);
    uv_tcp_bind(&tcpServer->server, (const struct sockaddr*)&tcpServer->addr, 0);
    int r = uv_listen((uv_stream_t*)&tcpServer->server, 128, on_new_connection);
    if (r) {
        fprintf(stderr, "Listen error %s\n", uv_strerror(r));
        // return 1;
    }
}


// int mains() {
//     loop = uv_default_loop();

//     uv_tcp_t server;
//     uv_tcp_init(loop, &server);

//     uv_ip4_addr("0.0.0.0", 7000, &addr);

//     uv_tcp_bind(&server, (const struct sockaddr*)&addr, 0);
//     int r = uv_listen((uv_stream_t*)&server, 128, on_new_connection);
//     if (r) {
//         fprintf(stderr, "Listen error %s\n", uv_strerror(r));
//         return 1;
//     }
//     return uv_run(loop, UV_RUN_DEFAULT);
// }
