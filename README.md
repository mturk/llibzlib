# llibzlib : Overview

llibzlib is Microsoft Windows port of [Zlib](https://zlib.net)
project providing only the library part of zlib project.

Headers and make files are manually created from original template
files, meaning that there is no need for additional configuration steps.

Source files are kept intact ensuring that llibzlib will behave
exactly the same as original zlib.

llibzlib uses `ZLIB_WINAPI`, so when you are linking this
library make sure to add `-DZLIB_WINAPI` to your project `CFLAGS` at compile time.

# License

The code in this repository is licensed under the [zlib/boost](LICENSE.txt)
according to the upstream project.
