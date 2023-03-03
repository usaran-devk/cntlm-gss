### stub library build
add_library(gssapi_krb5_stub SHARED libgssapi_krb5-stub.c)

set(SONAME "libgssapi_krb5.so.2")

set_property(TARGET gssapi_krb5_stub PROPERTY NO_SONAME TRUE)
set_property(TARGET gssapi_krb5_stub APPEND_STRING
    PROPERTY
        LINK_FLAGS " -Wl,-soname,${SONAME}"
)
