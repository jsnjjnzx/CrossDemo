CrossDemo — Windows 11 x64 test package

Extract the entire ZIP to a folder, then double-click QtLiquidSurface.exe.
Keep the DLLs, platforms and qml folders next to the EXE.
Qt and Visual Studio do not need to be installed.

Drag the glass panel, or focus it with Tab and use the arrow keys.
The three bottom buttons pause/play, switch the contrast pattern, and change frosting.
Hover over a button for its label. Esc closes the window.
Time, date and weather are sample content; no launch/search functionality is implemented.

The glass samples the app's own animated background. It does not capture the desktop.
Windows animation, transparency and high-contrast preferences are respected.

CI runs pixel comparisons through Direct3D WARP. Normal launch uses Qt's default
graphics selection on your machine. Actual appearance, DPI and performance need testing.

Please compare border/corner refraction, moving background, text clarity, dragging,
and behavior at your usual Windows display scale. This test build is not code-signed.

Source and build workflow: https://github.com/jsnjjnzx/CrossDemo
