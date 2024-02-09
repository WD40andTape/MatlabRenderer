# *3D Rendering Toolbox*: Color images and depth maps from 3D meshes

[![View on GitHub](https://img.shields.io/badge/GitHub-Repository-171515)](https://github.com/WD40andTape/MatlabRenderer)
<!--[![View on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)]()-->
<!--[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)]()-->

<img src="figure.gif" width="800px">

## Functions and Classes

| Name | Description
| -- | -- |
| `world2image` | Project world points, edges, and faces into image space. |
| `rasterize` | Rasterize projected mesh to form an image composed of pixels. |
| `raycast` | Compute ray direction from the camera to pixels. |
| `clip` | Clip faces, edges, vertices in the clip space of the graphics pipeline. Used by `world2image`. |
| `edgefcn` | Test whether 2D points are within triangular faces. Used by `edgefcn`. |
| `Camera` | Object for plotting a camera and storing its properties.<ul><li>*Properties*</li><ul><li>`projectionMatrix` : 4-by-4 projection matrix.</li><li>`imageSize` : Camera resolution, `[width height]`.</li><li>`t` : Camera translation, `[x y z]`.</li><li>`R` : 3-by-3 camera rotation matrix.</li><li>`plotHandles` : Graphics handles.</li></ul><li>*Methods*</li><ul><li>`Constructor` : Set and validate Camera properties.</li><li>`plotcamera` : Plot a mesh representing the camera.</li><li>`plotframe` : Plot the camera's Cartesian coordinate system.</li><li>`plotfov` : Plot a mesh representing the camera's field-of-view.</li><li>`setview` : Set the MATLAB axes' view to match the Camera object.</li></ul></ul> |
| `ProjectionMatrix` | Build, store, and modify a camera projection matrix.<ul><li>*Value* : 4-by-4 projection matrix.</li><li>*Methods*</li><ul><li>`Constructor` : Build a camera projection matrix, either with the camera's field-of-view and aspect ratio, or by defining the frustum coordinates directly.</li><li>`decompose` : Extract properties of the camera's view frustum.</li></ul></ul> |

## Example

Please see [`example.m`](example.m), which outputs the [figure above](figure.gif).

## Compatibility

Created in 2022b. All files are compatible with MATLAB release 2022a and later, but see the documentation of  individual files for their specific compatability. Compatible with all platforms.

## License and Citation

Published under MIT License (see [*LICENSE.txt*](LICENSE.txt)).

Please cite George Abrahams (https://github.com/WD40andTape/MatlabRenderer, https://www.linkedin.com/in/georgeabrahams).