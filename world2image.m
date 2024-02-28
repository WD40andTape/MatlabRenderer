function [ vertices, connectivity, ids ] = ...
        world2image( Cam, vertices, connectivity )
%WORLD2IMAGE Project world points, edges, and faces into image space.
% 
% SYNTAX
%   [ vertices, connectivity, ids ] = world2image( Cam, vertices )
%   [ vertices, connectivity, ids ] = world2image( __ , connectivity )
% 
% INPUTS
%   Cam           Instance of the provided Camera class, or structure array 
%                  containing the following fields:
%                   - projectionMatrix  4-by-4 projection matrix. It must 
%                                        be row-major and right-handed, 
%                                        with the camera aligned along the 
%                                        world coordinate system's negative 
%                                        Z-axis. Row-major order means that 
%                                        points are represented by row 
%                                        vectors and projected points are 
%                                        given by pre-multiplication, i.e., 
%                                        points * matrix.
%                   - imageSize         Camera resolution given as a 
%                                        2-element integer vector, in the 
%                                        form [width height].
%                   - t                 3-element numeric vector specifying 
%                                        the camera's translation  
%                                        (position), in world units, in the 
%                                        form [X Y Z].
%                   - R                 3-by-3 rotation matrix specifying 
%                                        the camera's 3D rotation 
%                                        (orientation). It must be 
%                                        right-handed and row-major. 
%                                        Row-major order means that the 
%                                        rows of R denote its basis 
%                                        vectors, i.e.,
%                                        [X1 Y1 Z1; X2 Y2 Z2; X3 Y3 Z3].
%                 Note that world2image does not validate the camera 
%                  parameters, as this is handled by the provided Camera 
%                  class. Therefore, if a structure array is used instead 
%                  of this class, be aware that the camera parameters will 
%                  not be validated.
%   vertices      Nx3 array of vertices, where N is the number of vertices, 
%                  and each vertex is in the form [X Y Z] in the world
%                  coordinate system.
%   connectivity  Mx1, Mx2 or Mx3 array where each row indexes 
%                  the vertices of a vertex, edge, or face primitive, 
%                  respectively. Faces need to be defined with a clockwise 
%                  winding, as backfaces will be culled. Default: Mx1 array 
%                  defining unlinked vertices.
% 
% OUTPUTS
%   vertices      Px3 array of vertices, where P is the number of vertices, 
%                  and each vertex is in the form [X Y Z]. X and Y are in 
%                  image space, i.e., measured in pixels, where the 
%                  upper-left pixel center is at (1,1). Z is in world 
%                  space, i.e., the distance from the camera along the 
%                  Z-dimension, measured in world units, and is used for 
%                  Z-buffering during rasterization. Vertices may be added 
%                  or removed due to clipping and backface culling.
%   connectivity  Same definition and order as input. Primitives completely 
%                  outside of the viewing frustum are removed. If the 
%                  primitives are triangles, then the output may contain 
%                  additional new triangles created in the process.
%   ids           Integer column vector which references the row indices of 
%                  the input connectivity array. The IDs of deleted 
%                  primitives will be removed. The IDs of new triangles 
%                  created by splitting existing triangles during clipping 
%                  will share the original ID.
% 
% EXAMPLE: Please see the file 'example.m'.
% 
% Please note that world2image depends on the functions, clip and 
% mustHaveFields, which are stored in seperate MATLAB files. Created in 
% 2022b. Compatible with 2020b and later. Compatible with all platforms. 
% Please cite George Abrahams: 
% https://github.com/WD40andTape/MatlabRenderer.

% Published under MIT License (see LICENSE.txt).
% Copyright (c) 2024 George Abrahams.
%  - https://github.com/WD40andTape/
%  - https://www.linkedin.com/in/georgeabrahams/
%  - https://scholar.google.com/citations?user=T_xxZLwAAAAJ

    arguments
        Cam (1,1) { mustHaveFields( Cam, ...
            [ "projectionMatrix", "imageSize", "t", "R" ] ) }
        vertices (:,3) { mustBeNonempty, mustBeNumeric, mustBeReal, ...
            mustBeNonNan, mustBeFinite }
        connectivity { mustBeNonempty, mustBeInteger, ...
            mustBe3DorLower } = ( 1 : size( vertices, 1 ) )'
    end
    ids = 1 : size( connectivity, 1 );
    % Backface culling for triangular meshes. This removes faces whose
    % normals are pointing away from the camera.
    if size( connectivity, 2 ) == 3
        A = vertices(connectivity(:,1),:);
        B = vertices(connectivity(:,2),:);
        C = vertices(connectivity(:,3),:);
        normals = cross( B - A, C - A );
        normals = normals ./ vecnorm( normals, 2, 2 );
        barycenters = mean( cat( 3, A, B, C ), 3 );
        lineOfSight = barycenters - Cam.t;
        isBackFacing = dot( normals, lineOfSight, 2 ) > 0;
        connectivity(isBackFacing,:) = [];
        ids(isBackFacing) = [];
    end
    verticesCameraSpace = ( vertices - Cam.t ) * Cam.R';
    % Convert points from Cartesian to homogenous space.
    verticesCameraSpace = ...
        [ verticesCameraSpace, ones( size( verticesCameraSpace, 1 ), 1 ) ];
    % Project points from camera space to homogenous clipping space.
    verticesClipSpace = verticesCameraSpace * Cam.projectionMatrix;
    % Clipping updates the scene so that no geometry appears outside of the 
    % camera's viewing frustum. Faces may be modified, created, or 
    % removed.
    [ verticesClipSpace, connectivity, oldIds ] = ...
        clip( verticesClipSpace, connectivity );
    ids = ids(oldIds);
    % Normalize points from homogenous clip space to Cartesian NDC space.
    % This is known as the perspective divide.
    verticesNdcSpace = verticesClipSpace(:,1:2) ./ ...
        verticesClipSpace(:,4);
    % Viewport transform from NDC to raster space. 
    % Accounts for the inverted Y-axis.
    verticesRasterSpace(:,1) = ...
        (verticesNdcSpace(:,1) + 1) * 0.5 * (Cam.imageSize(1) - 1);
    verticesRasterSpace(:,2) = ...
        (1 - (verticesNdcSpace(:,2) + 1) * 0.5) * (Cam.imageSize(2) - 1);
    % Accounts for 1-based pixel indexing.
    verticesRasterSpace = verticesRasterSpace + 1;
    % Add the Z-coordinate to the vertex. This is used for rasterization
    % to decide which face is closest to the camera and therefore should
    % be rendered (z-buffering). We use the world Z-coordinates, so that 
    % the Z-values of the rastered depth maps are in world units.
    verticesCameraSpace = ...
        verticesClipSpace * pinv( Cam.projectionMatrix );
    vertices = verticesRasterSpace;
    vertices(:,3) = -verticesCameraSpace(:,3);
end

%% Validation functions

function mustBe3DorLower( a )
%MUSTBE3DORLOWER throws an error if the size of the 2nd dimension of a is 
% more than 3, i.e., a must represent points, lines, or triangles.
    if size( a, 2 ) > 3
        id = "world2image:Validators:InvalidPrimitives";
        msg = "size( x, 2 ) must be <= 3, representing points, " + ...
            "lines, or triangles.";
        throwAsCaller( MException( id, msg ) )
    end
end