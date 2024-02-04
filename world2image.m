function [ vertices, connectivity, ids ] = ...
        world2image( Camera, vertices, connectivity )
%WORLD2IMAGE
%Depends on the seperate function, clip.
    arguments
        Camera (1,1) { mustHaveFields( Camera, ...
            [ "imageSize", "projectionMatrix", "t", "R" ] ) }
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
        lineOfSight = barycenters - Camera.t;
        isBackFacing = dot( normals, lineOfSight, 2 ) > 0;
        connectivity(isBackFacing,:) = [];
        ids(isBackFacing) = [];
    end
    verticesCameraSpace = ( vertices - Camera.t ) * Camera.R';
    % Convert points from Cartesian to homogenous space.
    verticesCameraSpace = ...
        [ verticesCameraSpace, ones( size( verticesCameraSpace, 1 ), 1 ) ];
    % Project points from camera space to homogenous clipping space.
    verticesClipSpace = verticesCameraSpace * Camera.projectionMatrix;
    % Clipping updates the scene so that no geometry appears outside of the 
    % camera's viewing frustum. Faces may be modified, created, or 
    % removed.
    [ verticesClipSpace, connectivity, oldIds ] = ...
        clip( verticesClipSpace, connectivity );
    ids = ids(oldIds);
    % Normalize points from homogenous clip space to Cartesian NDC space.
    % This is known as the perspective divide. The Z coordinate is kept,
    % which is explained later.
    verticesNdcSpace = verticesClipSpace(:,1:2) ./ ...
        verticesClipSpace(:,4);
    % Viewport transform from NDC to raster space. 
    % Accounts for the inverted Y-axis.
    verticesRasterSpace(:,1) = ...
        (verticesNdcSpace(:,1) + 1) * 0.5 * (Camera.imageSize(1) - 1);
    verticesRasterSpace(:,2) = ...
        (1 - (verticesNdcSpace(:,2) + 1) * 0.5) * (Camera.imageSize(2) - 1);
    % Accounts for 1-based pixel indexing.
    verticesRasterSpace = verticesRasterSpace + 1;
    % Add the Z-coordinate to the vertex. This is used for rasterization
    % to decide which face is closest to the camera and therefore should
    % be rendered.
    verticesCameraSpace = ...
        verticesClipSpace * pinv( Camera.projectionMatrix );
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