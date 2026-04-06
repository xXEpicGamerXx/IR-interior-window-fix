# IR Interior Window Fix

A Linux and Proton shader fix for Interstellar Rift interior smart-glass Windows.

## Issue

On Linux, when running Interstellar Rift via Proton, interior window devices render incorrectly. In the affected state, the glass on such devices may render as solid black or as a blocky oblong shape covering large portions of the screen.

This behavior is due to the shader of the material having numerous use before assign errors and improper use of the smoothstep function resulting in undefined behavior that happens to work fine on Windows but breaks on Linux.

## The Fix

The fix replaces the interior window shader and material configuration with stable shader code while keeping the overall appearance reasonably close to the effect seen on Windows.

It currently does not fix the smart-glass transition interaction. That issue is caused by unstable game-side C# behavior and would require patching the game code rather than only replacing the shader and material files. That is currently out of scope for this project, but planned for the future.

## Installation

1. Locate the Interstellar Rift installation directory.
   On Linux with Steam, this is commonly:
   `/home/<user>/.local/share/Steam/steamapps/common/Interstellar Rift`

2. Copy the `Content/` folder from this repository into the game directory overwtiting existing files.

After installation, the final file layout in the game directory should include:

```
Interstellar Rift/
  Content/
    Materials/
      [InteriorWindowDynamicMat_01].lua
    Shaders/
      InteriorWindowShader_01.glsl
```
