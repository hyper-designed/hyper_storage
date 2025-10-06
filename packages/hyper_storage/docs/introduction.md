### Welcome to Hyper Storage docs

Hyper Storage unifies local key-value storage in Flutter with a single, consistent API.
Switch between SharedPreferences, Hive, or any custom backend without changing a single line of app logic.

# Motivation

`hyper_storage` aims to abstract away the underlying storage mechanism, allowing you to switch
between different backends with one line of code change. This makes it easy to adapt your application to different
storage needs without changing your business logic.

Packages like, `shared_preferences`, `hive` and `flutter_secure_storage` are popular choices for local storage in
Flutter applications. However, each of these packages has its own API and usage patterns, which can lead to code
duplication and increased complexity when you need to switch to a different storage solution. `hyper_storage` solves
this problem by providing a unified API that works with multiple backends, allowing you to easily switch between them
without changing your application code.

# Table of Contents

- [Getting Started](getting_started.md)
- [Backends](backends.md)
- [Item Holders](item_holders.md)
- [Containers](containers.md)
- [Reactivity](reactivity.md)

# License

```
BSD 3-Clause License

Copyright (c) 2025, Hyperdesigned

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

```
