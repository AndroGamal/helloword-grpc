import os
import sys

import grpc
import hello_pb2
import hello_pb2_grpc


SERVER_ADDRESS = os.environ.get(
    "GRPC_SERVER_ADDRESS",
    "helloword-grpc-git.andro.blitz.cloud:443",
)
CONNECTION_TIMEOUT_SECONDS = 10
RPC_TIMEOUT_SECONDS = 10


def main():
    credentials = grpc.ssl_channel_credentials()

    with grpc.secure_channel(SERVER_ADDRESS, credentials) as channel:
        try:
            grpc.channel_ready_future(channel).result(
                timeout=CONNECTION_TIMEOUT_SECONDS
            )
            client = hello_pb2_grpc.GreeterStub(channel)
            response = client.SayHello(
                hello_pb2.HelloRequest(name="World"),
                timeout=RPC_TIMEOUT_SECONDS,
            )
        except grpc.FutureTimeoutError:
            print(
                f"Connection timed out after {CONNECTION_TIMEOUT_SECONDS}s: "
                f"{SERVER_ADDRESS}",
                file=sys.stderr,
            )
            return 1
        except grpc.RpcError as error:
            print(
                f"gRPC call failed: code={error.code()} "
                f"details={error.details()}",
                file=sys.stderr,
            )
            print(f"Debug: {error.debug_error_string()}", file=sys.stderr)
            return 1

    print("Server response:", response.message)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
