cmake_minimum_required(VERSION 2.8.12)
set(CMAKE_VERBOSE_MAKEFILE ON)
project(cntlm C)

include(GNUInstallDirs)

option(ENABLE_KERBEROS "Enable Kerberos support" ON)
option(WITH_GSS_STUB "Build with built-in stub of libgssapi_krb5.so.2 (usefull for cross-compile)" OFF)
option(WITH_SYSTEMD "Generate unit file depend on given version, use -DSYSTEMD_VERSION=<ver> to provide required version" ON)

set(_cflags)
set(_defines)
set(_libs)
set(_includes)

file(READ "VERSION" VERSION)
string(STRIP "${VERSION}" VERSION)

message(STATUS "*** Build ${PROJECT_NAME} ver. ${VERSION}")

# CMAKE_C_BYTE_ORDER: from version 3.20
if(CMAKE_C_BYTE_ORDER STREQUAL "BIG_ENDIAN")
    set(BIG_ENDIAN TRUE)
elseif(CMAKE_C_BYTE_ORDER STREQUAL "LITTLE_ENDIAN")
    set(BIG_ENDIAN FALSE)
else()
    try_run(_big_endian _big_endian_compiled ${CMAKE_BINARY_DIR}/_big_endian
        SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/config/big_endian.c
    )

    if(_big_endian_compiled AND NOT "${_big_endian}" STREQUAL "FAILED_TO_RUN")
        if(${_big_endian} EQUAL 0)
            set(BIG_ENDIAN TRUE)
        else()
            set(BIG_ENDIAN FALSE)
        endif()
    else()
        message(FATAL_ERROR "Cannot detect byte order, CMAKE_C_BYTE_ORDER='${CMAKE_C_BYTE_ORDER}' and big_endian test FAILED_TO_RUN!")
    endif()
endif()

if (CMAKE_VERSION VERSION_LESS "3.1")
    if (CMAKE_C_COMPILER_ID STREQUAL "GNU")
        set (CMAKE_C_FLAGS "-std=gnu99 ${CMAKE_C_FLAGS}")
    endif ()
else ()
    set (CMAKE_C_STANDARD 99)
endif ()

include(CheckSymbolExists)
include(CheckTypeSize)
check_symbol_exists("strdup" "string.h" HAVE_STRDUP)
check_symbol_exists("gethostname" "unistd.h" HAVE_GETHOSTNAME)

list(APPEND CMAKE_EXTRA_INCLUDE_FILES "sys/socket.h")
check_type_size("socklen_t" HAVE_SOCKLEN_T)

configure_file(config.h.in config.h)
list(APPEND _includes ${CMAKE_BINARY_DIR})

if(NOT DEFINED SYSCONF_INSTALL_DIR)
    set(SYSCONF_INSTALL_DIR "${CMAKE_INSTALL_FULL_SYSCONFDIR}")
endif()

configure_file(doc/cntlm.conf.in ${CMAKE_BINARY_DIR}/cntlm.conf @ONLY)
install(FILES ${CMAKE_BINARY_DIR}/cntlm.conf DESTINATION ${SYSCONF_INSTALL_DIR})

include(cmake/systemd.cmake)

install(FILES
    README README.md COPYRIGHT LICENSE doc/cntlm.conf
    DESTINATION ${CMAKE_INSTALL_DOCDIR}
)
install(FILES
    doc/cntlm.1
    DESTINATION ${CMAKE_INSTALL_MANDIR}/man1
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

list(APPEND _cflags -Wall -Wextra -Werror)
if (NOT (CMAKE_COMPILER_IS_GNUCC AND CMAKE_C_COMPILER_VERSION VERSION_LESS "6.0"))
    list(APPEND _cflags -Wpedantic)
endif()

add_executable(${PROJECT_NAME} ${_sources})
target_link_libraries(${PROJECT_NAME} ${_libs})
target_include_directories(${PROJECT_NAME} PRIVATE ${_includes})
target_compile_options(${PROJECT_NAME} PRIVATE ${_cflags})
target_compile_definitions(${PROJECT_NAME} PRIVATE ${_defines})

set_target_properties(${PROJECT_NAME}
    PROPERTIES
        SKIP_BUILD_RPATH TRUE
)

install(TARGETS ${PROJECT_NAME} DESTINATION ${CMAKE_INSTALL_SBINDIR})

install(FILES doc/add-user-keytab.sh
    DESTINATION ${CMAKE_INSTALL_SBINDIR}
    RENAME "cntlm-keytab-install"
    PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
)
