
#include <grpcpp/grpcpp.h>
#include "hello.grpc.pb.h"

#include <iostream>
#include <memory>
#include <string>

class GreeterService final : public hello::Greeter::Service {
public:
    grpc::Status SayHello(
        grpc::ServerContext* context,
        const hello::HelloRequest* request,
        hello::HelloReply* reply) override {

        const std::string name =
            request->name().empty() ? "World" : request->name();

        reply->set_message("Hello " + name + "!");

        return grpc::Status::OK;
    }
};

int main() {
    const std::string address = "127.0.0.1:50051";
    GreeterService service;

    grpc::ServerBuilder builder;
    builder.AddListeningPort(
        address,
        grpc::InsecureServerCredentials()
    );
    builder.RegisterService(&service);

    std::unique_ptr<grpc::Server> server = builder.BuildAndStart();

    if (!server) {
        std::cerr << "Failed to start gRPC server\n";
        return 1;
    }

    std::cout << "gRPC server listening on "
              << address << '\n';

    server->Wait();
    return 0;
}
