# *3D Rendering Toolbox*: Color images and depth maps from 3D meshes

[![View on GitHub](https://img.shields.io/badge/GitHub-Repository-171515)](https://github.com/WD40andTape/MatlabRenderer)
[![View on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://mathworks.com/matlabcentral/fileexchange/159386-3d-rendering-toolbox-color-image-and-depth-map-from-mesh)
[![Open in MATLAB Online](https://www.mathworks.com/images/responsive/global/open-in-matlab-online.svg)](https://matlab.mathworks.com/open/fileexchange/v1?id=159386&file=example.m)

Implementation of the computer graphics pipeline for triangulated meshes, in addition to a number of camera plotting functions. Handles both perspective and orthographic projection.

A notable use case is to simulate RGB or Kinect (depth) camera images for computer vision applications.
<img src="figure.gif" width="600px">

The codebase is compact, extensively documented, and uses only MATLAB built-in functions.

## Functions and Classes

| Name | Description
| -- | -- |
| `world2image` | Project world points, edges, and faces into image space. |
| `rasterize` | Rasterize projected mesh to form an image composed of pixels. |
| `raycast` | Compute rays from the camera's optical center to its pixels. |
| `clip` | Clip faces, edges, vertices in the clip space of the graphics pipeline. Used by `world2image`. |
| `edgefcn` | Test whether 2D points are within triangular faces. Used by `rasterize`. |
| `Camera` | Object for plotting a camera and storing its properties.<ul><li>*Properties*</li><ul><li>`projectionMatrix` : 4-by-4 projection matrix.</li><li>`imageSize` : Camera resolution, `[width height]`.</li><li>`t` : Camera translation, `[x y z]`.</li><li>`R` : 3-by-3 camera rotation matrix.</li><li>`plotHandles` : Graphics handles.</li></ul><li>*Methods*</li><ul><li>`Constructor` : Set and validate Camera properties.</li><li>`plotcamera` : Plot a mesh representing the camera.</li><li>`plotframe` : Plot the camera's Cartesian coordinate system.</li><li>`plotfov` : Plot a mesh representing the camera's field-of-view.</li><li>`setview` : Set the MATLAB axes' view to match the Camera object.</li></ul></ul> |
| `ProjectionMatrix` | Build and inspect a perspective or orthographic camera projection matrix.<ul><li>*Value* : 4-by-4 projection matrix.</li><li>*Methods*</li><ul><li>`Constructor` : Build the projection matrix, either with the camera's field-of-view and aspect ratio, by defining the frustum coordinates directly, or by converting from a camera intrinsic matrix.</li><li>`decompose` : Extract properties of the camera's view frustum.</li></ul></ul> |

For full documentation, please see the respective MATLAB file, or use the `doc` command, e.g., `doc world2image`.

## Example

Please see [`example.m`](example.m), which outputs the [figure above](figure.gif).

## Notes

- The toolbox was designed to have only minimal internal dependencies. Therefore `Camera`, `clip`, `edgefcn`, etc. can largely be used independently of the rest of the toolbox. The toolbox's individual functions and classes could be useful for *different* rendering pipelines, for example, to rasterize 2D vector graphics, or beyond the computer graphics pipeline, for example, to simply plot the location of a camera within a scene.

- As the renderer runs on the CPU and uses only MATLAB code, its speed is limited. On a standard laptop, for a scene with 8000 faces and at a resolution of 300x300, I get around 12 fps. Nevertheless, for applications which don't need a high speed, having everything within MATLAB is handy.

- Does not currently implement interpolated face colors (from colored vertices) or lighting.

- If the user has a camera intrinsic matrix, rather than a projection matrix, e.g., when simulating a camera calibrated in MATLAB, the ProjectionMatrix class can be used to convert this to the necessary format.

## Compatibility

Created in 2022b. All files are compatible with MATLAB release 2022a and later, but see the documentation of  individual files for their specific compatability. Compatible with all platforms. No external dependencies.

## License and Citation

Published under MIT License (see [*LICENSE.txt*](LICENSE.txt)).

Please cite George Abrahams (https://github.com/WD40andTape/MatlabRenderer, https://www.linkedin.com/in/georgeabrahams).