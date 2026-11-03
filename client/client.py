
import grpc
import hello_pb2
import hello_pb2_grpc


def main():
    server_address = "helloword-grpc-1a831.containers.snapdeploy.app:443"

    credentials = grpc.ssl_channel_credentials()

    with grpc.secure_channel(server_address, credentials) as channel:
        try:
            grpc.channel_ready_future(channel).result(timeout=15)

            client = hello_pb2_grpc.GreeterStub(channel)

            request = hello_pb2.HelloRequest(name="World")

            response = client.SayHello(request, timeout=15)

            print("Server response:", response.message)

        except grpc.FutureTimeoutError:
            print("Connection timeout: Cannot establish gRPC connection")

        except grpc.RpcError as error:
            print("gRPC error:", error.code())
            print("Details:", error.details())
            print("Debug:", error.debug_error_string())


if __name__ == "__main__":
    main()
