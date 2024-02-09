function [ rays, pixels ] = raycast( Cam, pixels, isNormalize )
%RAYCAST Compute ray direction from the camera to pixels.
% 
% SYNTAX
%   rays = raycast( Cam, pixels )
%   [ rays, pixels ] = raycast( Cam )
% 
% INPUTS
%   Cam          Instance of the provided Camera class, or structure array 
%                 containing the following fields:
%                  - projectionMatrix  4-by-4 projection matrix. It must be 
%                                       row-major and right-handed, with 
%                                       the camera aligned along the world 
%                                       coordinate system's negative 
%                                       Z-axis. Row-major order means that 
%                                       points are represented by row 
%                                       vectors and projected points are 
%                                       given by pre-multiplication, i.e., 
%                                       points * matrix.
%                  - imageSize         Camera resolution given as a 
%                                       2-element integer vector, in the 
%                                       form [width height].
%                  - R                 3-by-3 rotation matrix specifying 
%                                       the camera's 3D rotation 
%                                       (orientation). It must be 
%                                       right-handed and row-major. 
%                                       Row-major order means that the rows 
%                                       of R denote its basis vectors, i.e.
%                                       [X1 Y1 Z1; X2 Y2 Z2; X3 Y3 Z3].
%                Note that raycast does not validate the camera parameters, 
%                 as this is handled by the provided Camera class. 
%                 Therefore, if a structure array is used instead of this 
%                 class, be aware that the camera parameters will not be 
%                 validated.
%   pixels       Nx2 array of pixels for which to calculate ray direction, 
%                 where N is the number of pixels, and each row denotes a 
%                 pixel in the form, [X Y]. Subpixel coordinates are 
%                 accepted. Out-of-image pixels, i.e., outside of the 
%                 camera's field-of-view, are also accepted but display a 
%                 warning. Pixels containing NaN will return NaNs. By 
%                 default, a ray will be cast to every pixel within the 
%                 image, as defined by Cam.imageSize.
%   isNormalize  Scalar logical, by default false. If true, each output ray 
%                 output will have a Euclidean length of 1. If false, each 
%                 output ray will have a length equal to the distance 
%                 between the optical center and the pixel's position on 
%                 the near-clipping plane.
% 
% OUTPUTS
%   rays         Nx3 array of ray directions, where N is the number of 
%                 rays, with each ray direction in the form, [X Y Z], as 
%                 measured in the world coordinate system.
%   pixels       Nx2 array of pixels, where N is the number of pixels, with 
%                 each pixel in the form, [X Y], corresponding to the 
%                 respective ray in rays. If the pixels input was 
%                 provided, the pixels output will be identical. If it was 
%                 not provided, a ray will be cast to every pixel within 
%                 the image, as defined by Cam.imageSize.
% 
% EXAMPLE: Please see the file 'example.m'.
% 
% Please note that raycast depends on the function, mustHaveFields, which 
% is stored in a seperate MATLAB file. Created in 2022b. Compatible with 
% 2020b and later. Compatible with all platforms. Please cite George 
% Abrahams: https://github.com/WD40andTape/MatlabRenderer.

% Published under MIT License (see LICENSE.txt).
% Copyright (c) 2024 George Abrahams.
%  - https://github.com/WD40andTape/
%  - https://www.linkedin.com/in/georgeabrahams/
%  - https://scholar.google.com/citations?user=T_xxZLwAAAAJ

    arguments
        Cam (1,1) { mustHaveFields( Cam, ...
            [ "imageSize", "projectionMatrix", "R" ] ) }
        pixels (:,2) { mustBeNumeric, mustBeReal } = []
        isNormalize (1,1) logical = false
    end
    if isempty( pixels )
        % Cast rays from of all pixels within the image bounds.
        [ I, J ] = ...
            meshgrid( 1 : Cam.imageSize(1), 1 : Cam.imageSize(2) );
        pixels = [ I(:), J(:) ];
    elseif any( pixels < 1 | pixels > Cam.imageSize, "all" )
        warning( "Out-of-image pixels, i.e., that are " + ...
            "outside of the camera's field-of-view, were provided." )
    end
    nPixels = size( pixels, 1 );
    % Subtract 1 to account for 1-based pixel indexing.
    pRaster = pixels - 1;
    % Transform between coordinate systems in the order: raster -> 
    % normalized device coordinates (NDC) -> clip -> camera -> world.
    pNDC(:,1) = ( ( 2 * pRaster(:,1) ) / ( Cam.imageSize(1) - 1 ) ) - 1;
    pNDC(:,2) = 1 - ( ( 2 * pRaster(:,2) ) / ( Cam.imageSize(2) - 1 ) );
    % Set Z = -1, at the near plane. If Z = 1, points at the far plane. 
    % Set W = 1, to implictly convert from Cartesian coordinates to 
    % homogenous coordinates.
    pClip = [ pNDC, -ones( nPixels, 1 ), ones( nPixels, 1 ) ];
    pCamera = pClip * pinv( Cam.projectionMatrix );
    % Divide by W to convert back from homogenous to Cartesian coordinates.
    pCamera = pCamera(:,1:3) ./ pCamera(:,4);
    % Do not translate the rays as the output is a vector direction, not 
    % the pixel's point on the near plane.
    rays = pCamera * Cam.R;
    if isNormalize
        % Normalize to a distance of 1 to form a direction vector.
        rays = rays ./ vecnorm( rays, 2, 2 );
    end
end