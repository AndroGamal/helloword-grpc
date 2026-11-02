cmake_minimum_required(VERSION 3.5)
project(super_ads_api CXX)

# Custom file extension configuration
if(NOT DEFINED DEFAULT_SOURCE_EXTENSION)
    set(DEFAULT_SOURCE_EXTENSION "cc" CACHE STRING "Default source file extension (e.g., cc, cpp, cxx)")
endif()
if(NOT DEFINED DEFAULT_HEADER_EXTENSION)
    set(DEFAULT_HEADER_EXTENSION "h" CACHE STRING "Default header file extension (e.g., h, hpp, hxx)")
endif()

include(CheckIncludeFileCXX)

check_include_file_cxx(any HAS_ANY)
check_include_file_cxx(string_view HAS_STRING_VIEW)
check_include_file_cxx(coroutine HAS_COROUTINE)
if (NOT "${CMAKE_CXX_STANDARD}" STREQUAL "")
    # Do nothing
elseif (HAS_ANY AND HAS_STRING_VIEW AND HAS_COROUTINE)
    set(CMAKE_CXX_STANDARD 20)
elseif (HAS_ANY AND HAS_STRING_VIEW)
    set(CMAKE_CXX_STANDARD 17)
else ()
    set(CMAKE_CXX_STANDARD 14)
endif ()

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_executable(${PROJECT_NAME} main.${DEFAULT_SOURCE_EXTENSION})

# ##############################################################################
# If you include the drogon source code locally in your project, use this method
# to add drogon
# add_subdirectory(drogon)
# target_link_libraries(${PROJECT_NAME} PRIVATE drogon)
#
# and comment out the following lines
find_package(Drogon CONFIG REQUIRED)
target_link_libraries(${PROJECT_NAME} PRIVATE Drogon::Drogon)

# ##############################################################################

if (CMAKE_CXX_STANDARD LESS 17)
    message(FATAL_ERROR "c++17 or higher is required")
elseif (CMAKE_CXX_STANDARD LESS 20)
    message(STATUS "use c++17")
else ()
    message(STATUS "use c++20")
endif ()

aux_source_directory(controllers CTL_SRC)
aux_source_directory(filters FILTER_SRC)
aux_source_directory(plugins PLUGIN_SRC)
aux_source_directory(models MODEL_SRC)

drogon_create_views(${PROJECT_NAME} ${CMAKE_CURRENT_SOURCE_DIR}/views
                    ${CMAKE_CURRENT_BINARY_DIR})
# use the following line to create views with namespaces.
# drogon_create_views(${PROJECT_NAME} ${CMAKE_CURRENT_SOURCE_DIR}/views
#                     ${CMAKE_CURRENT_BINARY_DIR} TRUE)
# use the following line to create views with namespace CHANGE_ME prefixed
# and path namespaces.
# drogon_create_views(${PROJECT_NAME} ${CMAKE_CURRENT_SOURCE_DIR}/views
#                     ${CMAKE_CURRENT_BINARY_DIR} TRUE CHANGE_ME)

target_include_directories(${PROJECT_NAME}
                           PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}
                                   ${CMAKE_CURRENT_SOURCE_DIR}/models)
target_sources(${PROJECT_NAME}
               PRIVATE
               ${SRC_DIR}
               ${CTL_SRC}
               ${FILTER_SRC}
               ${PLUGIN_SRC}
               ${MODEL_SRC})
# ##############################################################################
# uncomment the following line for dynamically loading views
# set_property(TARGET ${PROJECT_NAME} PROPERTY ENABLE_EXPORTS ON)

# ##############################################################################

add_subdirectory(test)

# ---- gRPC Hello World ----

# find_package(Protobuf CONFIG REQUIRED)
# find_package(c-ares CONFIG REQUIRED)
# find_package(gRPC CONFIG REQUIRED)

find_package(Protobuf REQUIRED)
find_package(c-ares CONFIG REQUIRED)
find_package(gRPC CONFIG REQUIRED)

message(STATUS "Protobuf version: ${Protobuf_VERSION}")
message(STATUS "gRPC found successfully")

set(PROTO_FILE "${CMAKE_CURRENT_SOURCE_DIR}/proto/hello.proto")
set(GENERATED_DIR "${CMAKE_CURRENT_BINARY_DIR}/generated")

set(PROTO_SRC "${GENERATED_DIR}/hello.pb.cc")
set(PROTO_HDR "${GENERATED_DIR}/hello.pb.h")
set(GRPC_SRC "${GENERATED_DIR}/hello.grpc.pb.cc")
set(GRPC_HDR "${GENERATED_DIR}/hello.grpc.pb.h")

add_custom_command(
    OUTPUT
        "${PROTO_SRC}"
        "${PROTO_HDR}"
        "${GRPC_SRC}"
        "${GRPC_HDR}"

    COMMAND
        ${CMAKE_COMMAND} -E make_directory "${GENERATED_DIR}"

    COMMAND
        $<TARGET_FILE:protobuf::protoc>
        "--proto_path=${CMAKE_CURRENT_SOURCE_DIR}/proto"
        "--cpp_out=${GENERATED_DIR}"
        "--grpc_out=${GENERATED_DIR}"
        "--plugin=protoc-gen-grpc=$<TARGET_FILE:gRPC::grpc_cpp_plugin>"
        "${PROTO_FILE}"

    DEPENDS "${PROTO_FILE}"
    VERBATIM
)

add_library(hello_proto
    "${PROTO_SRC}"
    "${GRPC_SRC}"
)

target_include_directories(hello_proto PUBLIC
    "${GENERATED_DIR}"
)

target_link_libraries(hello_proto PUBLIC
    protobuf::libprotobuf
    gRPC::grpc++
)

add_executable(grpc_hello_server grpc_server.cc)
target_link_libraries(grpc_hello_server PRIVATE hello_proto)

add_executable(grpc_hello_client grpc_client.cc)
target_link_libraries(grpc_hello_client PRIVATE hello_proto)
