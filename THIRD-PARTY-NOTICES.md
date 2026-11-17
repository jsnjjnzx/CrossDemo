# Third-party components

The Windows package dynamically links Qt 6.11.1. Qt and its included third-party components retain their own copyright and license terms. Qt source and license information are available from [Qt 6.11.1 source archives](https://download.qt.io/official_releases/qt/6.11/6.11.1/single/) and [Qt licensing documentation](https://doc.qt.io/qt-6/licensing.html). The Qt DLLs are separate from the application executable.

Microsoft Visual C++ redistributable runtime DLLs are deployed from the Visual Studio 2022 redistributable directory. They remain Microsoft components under their applicable redistribution terms.

`assets/demo-background.png` is generated for this repository from a procedural color gradient. The original local-only `wallpaper.png` is excluded. Application icons in the macOS keyboard example are read from locally installed applications at runtime; no Apple application icons are bundled in this source repository.

The Swift/AppKit and Qt/AppKit comparison examples use Apple system frameworks available on macOS; those frameworks are not copied into this repository or the Windows package. References are listed in each example's README; no referenced third-party project source was copied.
