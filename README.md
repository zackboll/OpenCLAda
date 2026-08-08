# OpenCLAda

OpenCLAda is a thick Ada binding for the OpenCL host API. It provides
Ada-oriented types and operations for discovering compute devices, managing
OpenCL objects, compiling programs, launching kernels, and transferring data.

OpenCLAda is used to write the **host side** of an OpenCL application in Ada.
OpenCL kernels are still supplied as OpenCL C source, binaries, or built-in
kernels; this crate does not compile Ada code as OpenCL kernels.

This repository is an actively modernized continuation of
[Felix Krause's original OpenCLAda project][original-project]. The current
development version is `0.1.0-dev`.

## Project status

The project has been migrated to:

- the [Alire][alire] package manager and build workflow;
- Ada 2022;
- an AUnit-based test runner.

The binding currently includes packages for:

- platforms and devices;
- contexts and command queues;
- buffers, images, and other memory operations;
- programs and kernels;
- events and profiling;
- samplers;
- queued data transfers and kernel execution;
- OpenCL scalar and vector types.

The implementation has received substantial updates, but it should still be
considered a development release. API coverage and behavior may vary between
OpenCL implementations, and complete conformance to every OpenCL version is not
yet claimed.

OpenCL/OpenGL interoperability (`cl_gl`) from the original project is not
included in the current crate. It may be restored separately in the future.

## Requirements

To build OpenCLAda, you need:

- [Alire][alire] and an Alire-compatible GNAT toolchain;
- a system OpenCL loader/runtime providing the `OpenCL` library
  (`libOpenCL` on typical Unix-like systems);
- an OpenCL implementation from your hardware or platform vendor if one is not
  already installed.

The Ada binding contains its own imported API declarations, so OpenCL C headers
are not required merely to compile the crate. A usable OpenCL platform and
device are required to run OpenCL applications and the test suite.

The present project file links with `-lOpenCL`. Platforms that use a different
library name or linker convention may require an adjustment to `opencl.gpr`.
Recent development and testing have primarily used Linux; other platforms have
not been recently verified.

## Using the crate

When `openclada` is available from your configured Alire indexes, add it to an
Alire project with:

```sh
alr with openclada
```

For development against a local checkout, add the dependency and pin it to the
checkout:

```sh
alr with openclada --use=/path/to/OpenCLAda
```

The Alire crate name is `openclada`, and its GPR project is `opencl.gpr`.
Application code uses the root package `CL` and its child packages, for example
`CL.Platforms`, `CL.Contexts`, `CL.Memory`, `CL.Programs`, `CL.Kernels`, and
`CL.Queueing`.

The programs under [`tests/src`](tests/src) provide working examples of platform
and device discovery, context creation, buffers and images, program compilation,
kernel execution, and vector passing.

## Building

From the repository root:

```sh
alr build
```

The GPR project supports these scenario variables:

| Variable | Values | Default |
| --- | --- | --- |
| `mode` | `debug`, `release` | `debug` |
| `Library_Type` | `static`, `relocatable` | `static` |

They can be passed through Alire to GPRbuild, for example:

```sh
alr build -- -Xmode=release -XLibrary_Type=relocatable
```

## Tests

The `tests` directory is a separate Alire crate. It pins `openclada` to the
parent checkout and uses [AUnit][aunit] for its test runner.

Build and run the suite from that directory:

```sh
cd tests
alr build
alr run
```

Alternatively, after building:

```sh
./bin/tests
```

The tests compile and execute OpenCL kernels, so successful linking alone is not
enough: the machine must expose a functioning OpenCL platform and at least one
suitable device. Hardware, driver, and supported-feature differences can affect
the results.

## Documentation

The public package specifications under
[`src/interface`](src/interface) are the current API reference. The test drivers
are the most up-to-date usage examples.

Additional resources:

- [Khronos OpenCL API Registry][opencl-registry]
- [Khronos OpenCL Guide][opencl-guide]
- [Historical OpenCLAda wiki overview][historical-wiki]

The historical wiki documents the original project and may not match the
current API or build process.

## Contributing

Bug reports and contributions are welcome on the
[current GitHub repository][current-project]. When reporting runtime problems,
include the operating system, compiler and Alire versions, OpenCL platform,
device, and driver information where possible.

## License

OpenCLAda is distributed under the [ISC License][isc-license]. See
[`COPYING`](COPYING) for the full license text.

The original work is copyright Felix Krause. The current crate manifest credits
Felix Krause and Zack Boll as authors.

[alire]: https://alire.ada.dev/
[aunit]: https://github.com/AdaCore/aunit
[current-project]: https://github.com/zackboll/OpenCLAda
[historical-wiki]: https://github.com/flyx/OpenCLAda/wiki/Overview
[isc-license]: https://opensource.org/license/isc-license-txt
[opencl-guide]: https://github.com/KhronosGroup/OpenCL-Guide
[opencl-registry]: https://registry.khronos.org/OpenCL/
[original-project]: https://github.com/flyx/OpenCLAda