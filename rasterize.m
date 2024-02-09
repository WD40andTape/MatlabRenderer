function [ I, depth ] = rasterize( imageSize, vertices, faces, faceCData )
%RASTERIZE Rasterize projected mesh to form an image composed of pixels.
% 
% SYNTAX
%   [ I, depth ] = rasterize( imageSize, vertices, faces )
%   [ I, depth ] = rasterize( imageSize, vertices, faces, faceCData )
% 
% INPUTS
%   imageSize   Resolution of output images, in the form [width height].
%   vertices    Nx3 array of vertices, where N is the number of vertices, 
%                and each vertex is in the form [X Y Z]. X and Y are in 
%                image space, i.e. measured in pixels. Z is in world space,
%                i.e., the distance from the camera along the Z-dimension, 
%                measured in world units, and is used for Z-buffering.
%   faces       Mx3 array of faces, where M is the number of faces and 
%                each row indexes the 3 vertices of a triangle. Faces 
%                should be defined with a clockwise winding as backfaces 
%                will not be rendered.
%   faceCData   Face colors, specified as a single color for all faces, or 
%                one color per face.
%               For indexed colors, specify in one of these forms:
%                 - 1x1 scalar value, e.g., 0.5 or 1.
%                 - Mx1 vector, where M is the number of faces.
%               For true colors:
%                 - 1x3 vector of floats or unsigned integers defining an 
%                   RGB triplet.
%                 - Mx3 array of RGB triplets, as above, where M is the 
%                   number of faces.
%                 - Character vector or scalar string, e.g., 'red' or 
%                   "#FF0000".
%                 - Mx1 cell array of character vectors or string array, as 
%                   above.
%                By default, faceCData is set to 1 : size( faces, 1 ), so 
%                that the color denotes the face ID (row subscript of 
%                faces).
% 
% OUTPUTS
%   I           Rasterized image with the colors specified in faceCData. If 
%                faceCData was not specified, the values of I denote the ID
%                (row subscript of faces) of the visible face at each 
%                pixel. The resolution of I is determined by the imageSize 
%                input.
%   depth       Rasterized image giving the depth from the camera to the 
%                scene at each pixel, as measured in world units. The 
%                resolution of depth is the same as I, and is determined by 
%                the imageSize input.
% 
% EXAMPLE: Please see the file 'example.m'.
% 
% Please note that rasterize depends on the function, edgefcn, which is 
% stored in a seperate MATLAB file. Created in 2022b. Compatible with 2021a 
% and later. Compatible with all platforms. Please cite George Abrahams 
%  https://github.com/WD40andTape/MatlabRenderer.

% Published under MIT License (see LICENSE.txt).
% Copyright (c) 2024 George Abrahams.
%  - https://github.com/WD40andTape/
%  - https://www.linkedin.com/in/georgeabrahams/
%  - https://scholar.google.com/citations?user=T_xxZLwAAAAJ

    arguments
        imageSize (1,2) { mustBeInteger, mustBePositive }
        vertices (:,3) { mustBeNumeric, mustBeReal, mustBeNonNan, ...
            mustBeFinite }
        faces (:,3) { mustBeInteger }
        faceCData { processcolors( faceCData, faces ) } = ...
            ( 1 : size( faces, 1 ) )'
    end
    faceCData = processcolors( faceCData, faces );
    if isfloat( faceCData )
        I = nan( [ imageSize([2 1]), size( faceCData, 2 ) ], ...
            like=faceCData );
    else % isinteger( faceCData )
        I = zeros( [ imageSize([2 1]), size( faceCData, 2 ) ], ...
            like=faceCData );
    end
    depth = inf( imageSize([2 1]) );
    % Return early if no geometry is visible.
    if isempty( vertices ) || isempty( faces )
        return
    end
    % Rasterize each face in sequence. In scenes with a very high number of 
    % faces, it may be faster to loop over pixels instead and edgefcn 
    % also supports this.
    for iFace = 1 : size( faces, 1 )
        pFace = vertices(faces(iFace,:),:);
        % Generate a list of pixels within the face's 2D bounding box.
        % bbox has the format [ minX, minY, maxX, maxY ].
        bbox = [ min( pFace(:,1:2) ), max( pFace(:,1:2) ) ];
        bbox = min( max( 1, bbox ), repmat( imageSize, 1, 2 ) );
        bbox = [ floor( bbox(1:2) ), ceil( bbox(3:4) ) ];
        [ pixelI, pixelJ ] = meshgrid( bbox(1):bbox(3), bbox(2):bbox(4) );
        pixels = [ pixelI(:), pixelJ(:) ];
        % For all pixels in the bounding box, test whether they are inside
        % the face, and return their barycentric coordinates.
        [ inside, barycentric ] = edgefcn( pFace(:,1:2), 1:3, pixels );
        if any( inside )
            % For pixels within the face, calculate their depth value and
            % update the outputs if the depth is lower than the previously 
            % rasterized depth.
            z = 1 ./ sum( barycentric(inside,:) ./ pFace(:,3)', 2 );
            ind = sub2ind( imageSize([2 1]), ...
                pixels(inside,2), pixels(inside,1) );
            [ depth(ind), minI ] = ...
                min( [ depth(ind), z ], [], 2, "linear" );
            updated = minI > numel( ind );
            ind = ind(updated);
            I(ind) = faceCData(iFace,1);
            if size( faceCData, 2 ) == 3
                I(ind + prod( imageSize )) = faceCData(iFace,2);
                I(ind + 2 * prod( imageSize )) = faceCData(iFace,3);
            end
        end
    end
end

function colors = processcolors( colors, faces )
%PROCESSCOLORS Convert any accepted color format to an Mx1 vector or Mx3 
% array of colors defining either one indexed or RGB color per face, 
% repsectively. If an invalid color format is given, an error is thrown.
    if ( ischar( colors ) && isrow( colors ) ) || isstring( colors ) || ...
        iscellstr( colors )
        % Convert color names, such as 'red', or hexadecimal color codes,  
        % such as "#FF0000", to RGB.
        % Note validatecolor also throws errors for invalid color formats.
        colors = validatecolor( colors, "multiple" );
    elseif ~isnumeric( colors )
        id = "rasterize:Validators:UnrecognizedColor";
        msg = sprintf( "Colors of type '%s' are not recognized.", ...
            class( colors ) );
        throwAsCaller( MException( id, msg ) )
    end
    nFaces = size( faces, 1 );
    if nFaces ~= 1 && nFaces ~= 3 && size( colors, 2 ) == nFaces
        % Handle invalid 1xM or 3xM color format.
        warning( "Where a color is defined for each face, they " + ...
            "should be given as an Mx1 vector or Mx3 array." )
        colors = colors';
    end
    if size( colors, 1 ) == 1
        % Where a single color is given for all faces, apply this to each 
        % face.
        colors = repmat( colors, nFaces, 1 );
    elseif size( colors, 1 ) ~= nFaces
        id = "rasterize:Validators:WrongNumberOfColors";
        msg = sprintf( "Must define either one color for all of the " + ...
            "faces or one color per face (%i).", nFaces );
        throwAsCaller( MException( id, msg ) )
    end
    if size( colors, 2 ) ~= 1 && size( colors, 2 ) ~= 3
        id = "rasterize:Validators:InvalidColorFormat";
        msg = sprintf( "Colors must be defined as either single " + ...
            "values or RGB triplets, i.e., 1 or 3 values per color." );
        throwAsCaller( MException( id, msg ) )
    end
end