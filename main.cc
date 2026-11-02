#include <drogon/drogon.h>
#include <cerrno>
#include <cstdint>
#include <cstdlib>
#include <iostream>

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

    drogon::app().addListener("0.0.0.0", static_cast<std::uint16_t>(port));
    drogon::app().run();
    return 0;
}
