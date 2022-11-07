This is [Cntlm](http://cntlm.sourceforge.net/) **with Kerberos patch applied**.

Works on a Ubuntu 12.04 box, at least for me.

Dependency: [Kerberos](http://web.mit.edu/kerberos/).

### Main changes in this fork
* fixed [issue](https://github.com/metaphox/cntlm-gss/issues/2) for big number of group memberships in AD
* [POSIX POS36-C](https://wiki.sei.cmu.edu/confluence/display/c/POS36-C.+Observe+correct+revocation+order+while+relinquishing+privileges) issue fixed
* HTTP-1.1-persistent-connections-with-HTTP-1.0-clients patch applied
* Many bug from warnings fixed, warning-as-error now
* allow/deny list added as [forward] config section to limit hosts available through parent proxy (with optional auto-allow for HTTP redirects)
* SIGINT signal can be used to fast restart w/o wait closing connections

### Install
Prebuilt packages is available on Open Build Service in project [home:biserov:cntlm-gss](https://build.opensuse.org/package/show/home:biserov:cntlm-gss/cntlm) for the next OS list:
* OpenSuSE (Tumbleweed, Leap)
* Fedora, CentOS
* Debian, Ubuntu, Raspbian

Visit "[Download package](https://software.opensuse.org//download.html?project=home%3Abiserov%3Acntlm-gss&package=cntlm)" page and follow provided instructions.

### Build
**CMake**
```
$ mkdir .build
$ cd .build

$ cmake -DCMAKE_BUILD_TYPE="Release" ..
...or for use cross-compiler w/o access to gss headers...
$ cmake -DCMAKE_BUILD_TYPE="Release" -DCMAKE_INSTALL_PREFIX=/ -DCMAKE_TOOLCHAIN_FILE=/path/to/toolchain.cmake -DWITH_GSS_STUB=ON ..

$ cmake --build .

...

$ cmake --install . --strip
```

**Legacy**

**!WARNING!** I'm sorry but this method of configuring is obsolated and will be removed soon...

If Kerberos is compiled to a different location, say, $HOME/usr, compile Cntlm with

```
./configure --enable-kerberos

export LIBRARY_PATH=$HOME/usr/lib

export C_INCLUDE_PATH=$HOME/usr/include

make
```

To run it, try `cntlm --help` or `cntlm -v` and fix whatever it complains.

I have only the following lines in my ctnlm.conf file:

```
Auth GSS
Proxy proxy.server.domain.com:3128
NoProxy localhost, 127.0.0.*, 10.*, 192.168.*
Listen 3128

[forward]
#AllowRedirects  yes
Allow=*
```

The username, domain and password are all unset.

I could start it with `/home/me/usr/opt/cntlm-0.92.3/cntlm -c /home/me/usr/opt/cntlm-0.92.3/cntlm.conf` .

[doc/add-user-keytab.sh](doc/add-user-keytab.sh) script might be usefull to install cntlm keytab file on any system.
