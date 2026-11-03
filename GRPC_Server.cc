
#include <grpcpp/grpcpp.h>
#include "hello.grpc.pb.h"

#include <cerrno>
#include <chrono>
#include <csignal>
#include <cstdint>
#include <cstdlib>
#include <iostream>
#include <memory>
#include <string>
#include <thread>

namespace {

volatile std::sig_atomic_t shutdownSignal = 0;

void HandleShutdownSignal(int signal) {
    shutdownSignal = signal;
}

}  // namespace

class GreeterService final : public hello::Greeter::Service {
public:
    grpc::Status SayHello(
        grpc::ServerContext*,
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

    if (std::signal(SIGTERM, HandleShutdownSignal) == SIG_ERR ||
        std::signal(SIGINT, HandleShutdownSignal) == SIG_ERR) {
        std::cerr << "Failed to install SIGTERM/SIGINT handlers\n";
        return 1;
    }
#ifdef SIGBREAK
    if (std::signal(SIGBREAK, HandleShutdownSignal) == SIG_ERR) {
        std::cerr << "Failed to install SIGBREAK handler\n";
        return 1;
    }
#endif

    grpc::EnableDefaultHealthCheckService(true);

    grpc::ServerBuilder builder;
    int selectedPort = 0;
    builder.AddListeningPort(
        address,
        grpc::InsecureServerCredentials(),
        &selectedPort
    );
    builder.RegisterService(&service);

    std::unique_ptr<grpc::Server> server = builder.BuildAndStart();

    if (!server || selectedPort != port) {
        std::cerr << "Failed to bind gRPC server to " << address << '\n';
        return 1;
    }

    grpc::HealthCheckServiceInterface* healthService =
        server->GetHealthCheckService();
    if (healthService == nullptr) {
        std::cerr << "Failed to initialize the gRPC health check service\n";
        server->Shutdown();
        return 1;
    }
    healthService->SetServingStatus(true);

    std::cout << "gRPC server listening on " << address << std::endl;

    std::thread shutdownWatcher([&server, healthService]() {
        while (shutdownSignal == 0) {
            std::this_thread::sleep_for(std::chrono::milliseconds(100));
        }

        std::cerr << "Received signal " << shutdownSignal
                  << "; shutting down gRPC server" << std::endl;
        healthService->SetServingStatus(false);
        server->Shutdown(
            std::chrono::system_clock::now() + std::chrono::seconds(10)
        );
    });

    server->Wait();
    shutdownWatcher.join();
    std::cout << "gRPC server stopped" << std::endl;
    return 0;
}
