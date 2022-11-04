if(NOT WITH_SYSTEMD)
    return()
endif()


if(NOT DEFINED SYSTEMD_INSTALL_DIR)
    set(SYSTEMD_INSTALL_DIR "${CMAKE_INSTALL_PREFIX}/lib/systemd/system")
endif()

if(NOT DEFINED SYSTEMD_WORKINGDIR)
    #set(SYSTEMD_WORKINGDIR "${CMAKE_INSTALL_LOCALSTATEDIR}/log/cntlm")
    set(SYSTEMD_WORKINGDIR "%T")
endif()

if(NOT DEFINED SYSTEMD_VERSION)
    find_package(PkgConfig REQUIRED)
    pkg_check_modules(SYSTEMD libsystemd)
    if(NOT SYSTEMD_FOUND)
        pkg_check_modules(SYSTEMD REQUIRED libsystemd-daemon)
    endif()
endif()

set(cntlm_service_file "${CMAKE_BINARY_DIR}/cntlm.service")

message(STATUS "*** Generate ${cntlm_service_file} for version ${SYSTEMD_VERSION}")

configure_file(doc/cntlm.service.in "${cntlm_service_file}" @ONLY)

file(STRINGS "${cntlm_service_file}" _lines)

set(_result_str "")
set(_skip_lines FALSE)
foreach(_line IN LISTS _lines)
    if(${_line} MATCHES "^#systemd ([0-9]+|any)")
        string(REGEX REPLACE "^\\#systemd " "" _ver "${_line}")

        if(_ver STREQUAL "any")
            set(_skip_lines FALSE)
        else()
            string(REGEX REPLACE "\\+$" "" _ver "${_ver}")

            if(SYSTEMD_VERSION EQUAL ${_ver})
                set(_skip_lines FALSE)
            elseif(SYSTEMD_VERSION GREATER ${_ver})
                set(_skip_lines FALSE)
            else()
                set(_skip_lines TRUE)
            endif()
        endif()
    endif()

    if(NOT _skip_lines)
        set(_result_str "${_result_str}${_line}\n")
    endif()
endforeach()

file(WRITE "${cntlm_service_file}" ${_result_str})

install(FILES
    ${cntlm_service_file}
    DESTINATION ${SYSTEMD_INSTALL_DIR}
)
