
#include <grpcpp/grpcpp.h>
#include "hello.grpc.pb.h"

#include <iostream>
#include <memory>

int main() {
    auto channel = grpc::CreateChannel(
        "127.0.0.1:50051",
        grpc::InsecureChannelCredentials()
    );

    auto stub = hello::Greeter::NewStub(channel);

    hello::HelloRequest request;
    request.set_name("World");

    hello::HelloReply reply;
    grpc::ClientContext context;

    grpc::Status status =
        stub->SayHello(&context, request, &reply);

    if (!status.ok()) {
        std::cerr << "gRPC error: "
                  << status.error_message() << '\n';
        return 1;
    }

    std::cout << reply.message() << '\n';
    return 0;
}
