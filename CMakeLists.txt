cmake_minimum_required(VERSION 3.20)
project(cntlm-gss C)

file(READ "VERSION" VERSION)
string(STRIP "${VERSION}" VERSION)

message(STATUS "${PROJECT_NAME} ver. ${VERSION}")

option(ENABLE_KERBEROS "Enable Kerberos support" ON)

if(CMAKE_C_BYTE_ORDER STREQUAL "BIG_ENDIAN")
    set(config_endian 0)
    set(CONFIG_BIG_ENDIAN TRUE)
elseif(CMAKE_C_BYTE_ORDER STREQUAL "LITTLE_ENDIAN")
    set(config_endian 1)
    set(CONFIG_BIG_ENDIAN FALSE)
else()
    message(FATAL_ERROR "Cannot detect byte order, CMAKE_C_BYTE_ORDER='${CMAKE_C_BYTE_ORDER}'")
endif()

include(CheckSymbolExists)
include(CheckTypeSize)
check_symbol_exists("strdup" "string.h" HAVE_STRDUP)
check_symbol_exists("gethostname" "unistd.h" HAVE_GETHOSTNAME)

list(APPEND CMAKE_EXTRA_INCLUDE_FILES "sys/socket.h")
check_type_size("socklen_t" HAVE_SOCKLEN_T)

configure_file(config.h.in config.h)
include_directories(${CMAKE_BINARY_DIR})

set(_sources
    utils.c ntlm.c xcrypt.c config-file.c socket.c acl.c auth.c http.c forward.c direct.c scanner.c pages.c
    main.c
)
if(ENABLE_KERBEROS)
    list(APPEND _sources kerberos.c)
endif()
add_executable(cntlm-gss ${_sources})

if(ENABLE_KERBEROS)
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(KRB5GSSAPI REQUIRED mit-krb5-gssapi)

    target_link_libraries(cntlm-gss ${KRB5GSSAPI_LIBRARIES})
    target_include_directories(cntlm-gss PRIVATE ${KRB5GSSAPI_INCLUDE_DIRS})
    target_compile_options(cntlm-gss PRIVATE ${KRB5GSSAPI_CFLAGS_OTHER})
endif()
