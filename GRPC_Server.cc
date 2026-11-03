
#include <grpcpp/grpcpp.h>
#include "hello.grpc.pb.h"

#include <cerrno>
#include <cstdint>
#include <cstdlib>
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
    constexpr long defaultPort = 8080;
    long port = defaultPort;

    if (const char* portValue = std::getenv("PORT")) {
        char* end = nullptr;
        errno = 0;
        const long parsedPort = std::strtol(portValue, &end, 10);
        if (errno == ERANGE || end == portValue || *end != '\0' ||
            parsedPort < 1 || parsedPort > 65535) {
            std::cerr << "Invalid PORT value: " << portValue << '\n';
            return 1;
        }
        port = parsedPort;
    }

    const std::string address =
        "0.0.0.0:" + std::to_string(static_cast<std::uint16_t>(port));
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
