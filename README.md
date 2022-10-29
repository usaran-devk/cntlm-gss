This is [Cntlm](http://cntlm.sourceforge.net/) **with Kerberos patch applied**.

Works on a Ubuntu 12.04 box, at least for me.

Dependency: [Kerberos](http://web.mit.edu/kerberos/).

If Kerberos is compiled to a different location, say, $HOME/usr, compile Cntlm with

**CMake:**
```
$ mkdir .build
$ cd .build

$ cmake -DCMAKE_BUILD_TYPE="Release" ..
...or...
$ cmake -DCMAKE_BUILD_TYPE="Release" -DCMAKE_TOOLCHAIN_FILE=/path/to/toolchain.cmake -DWITH_GSS_STUB=ON ..

$ cmake --build .
```

**Legacy:**
`./configure --enable-kerberos`

`export LIBRARY_PATH=$HOME/usr/lib`

`export C_INCLUDE_PATH=$HOME/usr/include`

`make`

To run it, try `cntlm --help` or `cntlm -v` and fix whatever it complains.

I have only the following lines in my ctnlm.conf file:

```
Auth        GSS
Proxy		proxy.server.domain.com:3128
NoProxy		localhost, 127.0.0.*, 10.*, 192.168.*
Listen		3128

[forward]
#AllowRedirects  yes
Allow=*
```

The username, domain and password are all unset.

I could start it with `/home/me/usr/opt/cntlm-0.92.3/cntlm -c /home/me/usr/opt/cntlm-0.92.3/cntlm.conf` .
