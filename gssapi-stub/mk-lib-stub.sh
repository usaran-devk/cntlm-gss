#!/bin/bash

set -ex

export LC_ALL=C LC_LANG=C

lib_file=/usr/lib64/libgssapi_krb5.so
lib_filename=$(basename "$lib_file")

soname=$(readelf -d "$lib_file" | awk '/(SONAME)/{print substr($5,2,length($5)-2);q;}') #'

lib_name=${soname%%.*}
stub_name="${lib_name}-stub"

stub_src="$stub_name.c"

cat >"$stub_src" <<EOT
#include <stdlib.h>
#include <stdio.h>

// lib: $lib_filename
// SONAME: ${soname}

#define SHARED_LIB_NAME "${stub_name}.so"

void __attribute__ ((constructor)) _so_stub_init(void)
{
    fprintf(stderr, "%s cannot be used for process executing. Exiting... ", SHARED_LIB_NAME);
    exit(1);
}

#define _stub_code(name) void name(){}

typedef struct _stub_data_desc_struct {
    void *value;
} _stub_data_desc, *_stub_data_t;

static _stub_data_desc _stub_const = {"_stub_const"};

#define _stub_data(name) _stub_data_t  name = &_stub_const;

EOT

while read _type sym ; do
    case "${_type}" in
        #) echo "const void *$sym = NULL;" >>"$stub_src" ;;
        D) echo "_stub_data($sym);" >>"$stub_src" ;;
        T) echo "_stub_code($sym);" >>"$stub_src" ;;
    esac
done <<<$(nm -D "$lib_file" | awk '/ [DT] /{print $2,$3;}')

gcc -fPIC -shared "-Wl,-soname,${soname}" -o "$lib_filename" "$stub_src"
