% Example demonstrating the steps and outputs of the rendering process.
% If you don't want to run this, figure.gif is the resultant output.
% 
% Created in 2022b. Compatible with 2022a and later. Compatible with all 
% platforms. Please cite George Abrahams: 
% https://github.com/WD40andTape/MatlabRenderer.

% Published under MIT License (see LICENSE.txt).
% Copyright (c) 2024 George Abrahams.
%  - https://github.com/WD40andTape/
%  - https://www.linkedin.com/in/georgeabrahams/
%  - https://scholar.google.com/citations?user=T_xxZLwAAAAJ

PROJECTION_MATRIX = ProjectionMatrix( deg2rad( 70 ), 1, 0.1 );
% For an orthographic projection instead, uncomment the following:
% PROJECTION_MATRIX = ProjectionMatrix( -2.5, 2.5, -2.5, 2.5, 0.1, 100, ...
%     "orthographic" );
IMAGE_SIZE = [ 300, 300 ];
START_TRANSLATION = [ 0, 2.2, 2.2 ];
START_ROTATION = [ -1, 0, 0; 0, cosd(135), sind(135); ...
    0, sind(135), -cosd(135) ];

Cam = Camera( PROJECTION_MATRIX, IMAGE_SIZE, ...
    START_TRANSLATION, START_ROTATION );
[ vertices, faces ] = loadgeometry;
% Set up figure (f), axes (ax), and plots (h).
[ f, ax, h ] = setupfig( Cam, faces, vertices );

stepRotation = makehgtform( xrotate=0.03, zrotate=0.03 );
stepRotation = stepRotation(1:3,1:3);
while isgraphics( f )
    % Rotate (orbit) the camera by a small amount around the origin.
    Cam.t = Cam.t * stepRotation;
    Cam.R = Cam.R * stepRotation;
    % Project the world coordinates to image coordinates. Vertices and 
    % faces may be added or removed due to face culling and clipping, 
    % which remove geometry that the camera can't see. Where this occurs, 
    % idsImg gives the ID of the original face.
    [ verticesImg, facesImg, idsImg ] = ...
        world2image( Cam, vertices, faces );
    % Reverse world2image to find the world coordinates of the culled and 
    % clipped faces. THIS STEP IS NOT REQUIRED FOR RENDERING and only 
    % exists to demonstrate the internal functioning of world2image.
    verticesClipped = image2world( Cam, verticesImg );
    % Rasterize the projected geometry, converting from faces defined by 
    % vertices connected by edges to a pixelized image. Use the original 
    % face IDs as their color.
    [ I, depthMap ] = ...
        rasterize( Cam.imageSize, verticesImg, facesImg, idsImg' );
    % Update the axes.
    set( h(2), "Faces", facesImg, "Vertices", verticesClipped, ...
            "FaceVertexCData", idsImg' )
    set( h(3), "Faces", facesImg, "Vertices", verticesImg(:,1:2) )
    set( h(4), "CData", I )
    set( h(5), "CData", depthMap )
    drawnow
end

%% Helper functions.

function [ vertices, faces ] = loadgeometry
%LOADGEOMETRY Load and pre-process a mesh of the Newell teapot.
    % Load 3D object.
    [ vertices, quads ] = teapotGeometry;
    % Center on the X-Y plane.
    vertices = vertices - [ 0, 0, mean( vertices(:,3) ) ];
    % Convert quads to triangles.
    faces = nan( size(quads,1) * 2, 3 );
    faces(1:2:end,:) = quads(:,[ 1 2 3 ]);
    faces(2:2:end,:) = quads(:,[ 1 3 4 ]);
end

function [ f, ax, h ] = setupfig( Cam, faces, vertices )
%SETUPFIG Create the figure, axes, and plots for the example.
    f = figure( Color="w" );
    tl = tiledlayout( f, 2, 6, TileSpacing="compact", Padding="tight" );

    ax(1) = nexttile( tl, [1 2] );
    h(1) = patch( ax(1), Faces=faces, Vertices=vertices, ...
        CData=1:size( faces, 1 ), FaceColor="flat", EdgeColor="none" );
    material( h(1), "dull" )
    lightangle( ax(1), -7.5, 60 )
    Cam.plotcamera( ax(1), 0.75 )
    Cam.plotframe( ax(1), 0.75, "" )
    title( ax(1), "Scene and Camera" )

    ax(2) = nexttile( tl, [1 2] );
    h(2) = copyobj( h(1), ax(2) );
    lightangle( ax(2), -7.5, 60 )
    Cam.plotcamera( ax(2), 0.75 )
    Cam.plotfov( ax(2), 3.5 )
    title( ax(2), "Face Culling and Clipping" )
    
    ax(3) = nexttile( tl, [1 2] );
    h(3) = patch( ax(3), Faces=[], Vertices=[], FaceColor="none" );
    set( ax(3), "YDir", "reverse" )
    title( ax(3), "Projected Mesh" )
    
    ax(4) = nexttile( tl, 8, [1 2] );
    h(4) = imagesc( ax(4), [] );
    title( ax(4), "Rastered Colors" )
    
    ax(5) = nexttile( tl, [1 2] );
    h(5) = imagesc( ax(5), [] );
    set( ax(5), "Colormap", flipud( gray ), "CLim", [ 0.5 5 ] )
    title( ax(5), "Rastered Depths" )
    
    set( ax, "DataAspectRatio", [ 1 1 1 ], ...
        "XTick", [], "YTick", [], "ZTick", [], "Box", "on" )
    limRange = [ -1, 1 ] .* ( norm( Cam.t ) + 0.75 / 2 );
    set( ax(1:2), "View", [ -37.5 30 ], ...
        "XLim", limRange, "YLim", limRange, "ZLim", limRange )
    set( ax(3:5), "XLim", [ 1 Cam.imageSize(1) ], ...
        "YLim", [ 1 Cam.imageSize(2) ]  )
    
    % Map the faces' indexed colors to random true colors via the colormap.
    rng( 1 )
    colors = colorcube( size( faces, 1 ) );
    colors = colors( randperm( size( colors, 1 ) ), : );
    colors(1,:) = [ 0, 0, 0 ];
    set( ax([1 2 4]), "Colormap", colors, "CLim", [ 1 size( faces, 1 ) ] )
end

function vertices = image2world( Cam, vertices )
%IMAGE2WORLD Reverse world2image projection.
    if ~isempty( vertices )
        if Cam.projectionMatrix(4,4) == 0
            % Perspective projection matrix.
            directions = raycast( Cam, vertices(:,1:2), false );
            near = Cam.projectionMatrix.decompose.near;
            % near = Cam.projectionMatrix(4,3) / ...
            %     ( Cam.projectionMatrix(3,3) - 1 );
            vertices = Cam.t + directions .* ( vertices(:,3) ./ near );
        else % Cam.projectionMatrix(4,4) == 1
            % Orthographic projection matrix.
            [ directions, sources ] = ...
                raycast( Cam, vertices(:,1:2), true );
            near = ( Cam.projectionMatrix(4,3) + 1 ) / ...
                Cam.projectionMatrix(3,3);
            vertices = sources + directions .* ( vertices(:,3) - near );
        end
    end
end