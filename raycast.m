function [ rays, pixels ] = raycast( Camera, pixels )
%RAYCAST
% rays = raycast( Camera, pixels )
% [ rays, pixels ] = raycast( Camera )
% pixels = [x y]
% Pixel coordinates containing NaN return NaN rays. Subpixel coordinates are
% accepted. Out-of-image pixels, i.e., outside of the camera's field-of-view, are
% accepted but display a warning.
    arguments
        Camera (1,1) { mustHaveFields( Camera, ...
            [ "imageSize", "projectionMatrix", "R" ] ) }
        pixels (:,2) { mustBeNumeric, mustBeReal } = []
    end
    if isempty( pixels )
        % Cast rays from of all pixels within the image bounds.
        [ I, J ] = ...
            meshgrid( 1 : Camera.imageSize(1), 1 : Camera.imageSize(2) );
        pixels = [ I(:), J(:) ];
    elseif any( pixels < 1 | pixels > Camera.imageSize, "all" )
        warning( "Out-of-image pixels, i.e., that are " + ...
            "outside of the camera's field-of-view, were provided." )
    end
    nPixels = size( pixels, 1 );
    % Transform between coordinate systems in the order: pixel -> raster 
    % -> normalized device coordinates (NDC) -> clip -> camera -> world.
    % Subtract 1 to account for 1-based pixel indexing.
    pRaster = pixels - 1;
    pNDC(:,1) = ( ( 2 * pRaster(:,1) ) / ( Camera.imageSize(1) - 1 ) ) - 1;
    pNDC(:,2) = 1 - ( ( 2 * pRaster(:,2) ) / ( Camera.imageSize(2) - 1 ) );
    % Set Z = -1, at the near plane. If Z = 1, points at the far plane. 
    % Set W = 1, to implictly convert from Cartesian coordinates to 
    % homogenous coordinates.
    pClip = [ pNDC, -ones( nPixels, 1 ), ones( nPixels, 1 ) ];
    pCamera = pClip * pinv( Camera.projectionMatrix );
    % Divide by W to convert back from homogenous to Cartesian coordinates.
    pCamera = pCamera(:,1:3) ./ pCamera(:,4);
    % Do not translate the rays as the output is a vector direction, not 
    % the pixel's point on the near plane.
    rays = pCamera * Camera.R;
end