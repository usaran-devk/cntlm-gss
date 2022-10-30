cmake_minimum_required(VERSION 3.20)
project(cntlm-gss C)
include(GNUInstallDirs)

option(ENABLE_KERBEROS "Enable Kerberos support" ON)
option(WITH_GSS_STUB "Build with built-in stub of libgssapi_krb5.so.2 (usefull for cross-compile)" OFF)

set(_cflags)
set(_defines)
set(_libs)
set(_includes)

file(READ "VERSION" VERSION)
string(STRIP "${VERSION}" VERSION)

message(STATUS "*** Build ${PROJECT_NAME} ver. ${VERSION}")

set(SYSCONFDIR "${CMAKE_INSTALL_FULL_SYSCONFDIR}")

if(CMAKE_C_BYTE_ORDER STREQUAL "BIG_ENDIAN")
    set(BIG_ENDIAN TRUE)
elseif(CMAKE_C_BYTE_ORDER STREQUAL "LITTLE_ENDIAN")
    set(BIG_ENDIAN FALSE)
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
list(APPEND _includes ${CMAKE_BINARY_DIR})

configure_file(doc/cntlm-gss.conf.in cntlm-gss.conf @ONLY)
install(FILES ${CMAKE_BINARY_DIR}/cntlm-gss.conf DESTINATION ${CMAKE_INSTALL_SYSCONFDIR})

configure_file(doc/cntlm-gss.service.in cntlm-gss.service @ONLY)
install(FILES
    ${CMAKE_BINARY_DIR}/cntlm-gss.service
    README README.md COPYRIGHT LICENSE
    DESTINATION ${CMAKE_INSTALL_DOCDIR}
)

find_package(Threads REQUIRED)
list(APPEND _libs ${CMAKE_THREAD_LIBS_INIT})

set(_sources
    utils.c ntlm.c xcrypt.c config-file.c socket.c acl.c auth.c http.c forward.c direct.c scanner.c pages.c
    main.c
)

if(ENABLE_KERBEROS)
    message(STATUS "*** With Kerberos support enabled")
    list(APPEND _sources kerberos.c)

    if(NOT WITH_GSS_STUB)
        message(STATUS "*** using system mit-krb5-gssapi")
        find_package(PkgConfig REQUIRED)
        pkg_check_modules(KRB5GSSAPI REQUIRED mit-krb5-gssapi)
        list(APPEND _cflags ${KRB5GSSAPI_CFLAGS_OTHER})
        list(APPEND _includes ${KRB5GSSAPI_INCLUDE_DIRS})
        list(APPEND _libs ${KRB5GSSAPI_LIBRARIES})
    else()
        message(STATUS "*** using gssapi-stub")
        add_subdirectory(gssapi-stub)
        list(APPEND _includes gssapi-stub)
        list(APPEND _libs gssapi_krb5_stub)
    endif()
endif()

add_executable(cntlm-gss ${_sources})
target_link_libraries(cntlm-gss ${_libs})
target_include_directories(cntlm-gss PRIVATE ${_includes})
target_compile_options(cntlm-gss PRIVATE ${_cflags})
target_compile_definitions(cntlm-gss PRIVATE ${_defines})

set_target_properties(cntlm-gss
    PROPERTIES
        SKIP_BUILD_RPATH TRUE
)
#target_compile_options(cntlm-gss PRIVATE -Wall -Wextra -Wpedantic -Werror)

install(TARGETS cntlm-gss)
