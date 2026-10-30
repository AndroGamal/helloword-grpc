
import grpc
import hello_pb2 as hello_pb2
import hello_pb2_grpc as hello_pb2_grpc


def main():
    server_address = "127.0.0.1:50051"

    with grpc.insecure_channel(server_address) as channel:
        client = hello_pb2_grpc.GreeterStub(channel)

        request = hello_pb2.HelloRequest(name="World")

        try:
            response = client.SayHello(request, timeout=5)
            print("Server response:", response.message)

        except grpc.RpcError as error:
            print("gRPC error:", error.code())
            print(error.details())


if __name__ == "__main__":
    main()
