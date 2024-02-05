addpath( genpath( pwd ) ), clearvars, close all

PROJECTION_MATRIX = ProjectionMatrix( deg2rad(61), 1, 0.1 );
IMAGE_SIZE = [ 300 300 ];
% IMAGE_SIZE = 100;
CAMERA_TRANSLATION = [ 0 0 -4 ];
CAMERA_ROTATION = [ 1 0 0; 0 -1 0; 0 0 -1 ];

% Load 3D object and convert quads to triangles.
[ vertices, quads ] = teapotGeometry;
faces = nan( size(quads,1) * 2, 3 );
faces(1:2:end,:) = quads(:,[1 2 3]);
faces(2:2:end,:) = quads(:,[1 3 4]);

% Set up camera and position object.
vertices = vertices - [ 0, 0, mean( vertices(:,3) ) ];
Camera = Camera( PROJECTION_MATRIX, IMAGE_SIZE, ...
    CAMERA_TRANSLATION, CAMERA_ROTATION );

rotation = rotz( 180 ) * rotx( -135 ) * rotz( 0 ); % -135, 0
Camera.t = Camera.t * rotation;
Camera.R = Camera.R * rotation;

f = figure;
tl = tiledlayout( 2, 2, TileSpacing="tight", Padding="tight" );
% 
ax(1) = nexttile( tl );
h(1) = patch( ax(1), "Faces", faces, "Vertices", vertices, ...
    "CData", 1 : size( faces, 1 ), "FaceColor", "flat", "EdgeColor", "none" );
material( h(1), "dull" )
Camera.plotframe( ax(1), 0.75 )
Camera.plotcamera( ax(1), 0.75 )
Camera.plotfov( ax(1), 4.7 )
tRange = [ -norm( CAMERA_TRANSLATION ), norm( CAMERA_TRANSLATION ) ];
set( ax(1), "DataAspectRatio", [1 1 1], "View", [-37.5 30], ...
    "XLim", tRange, "YLim", tRange, "ZLim", tRange, ...
    "XTick", [], "YTick", [], "ZTick", [], "Box", "on" )
camlight( ax(1), 'right' )
title( ax(1), "Scene and Camera" )
% 
ax(2) = nexttile( tl );
h(2) = patch( ax(2), "Faces", [], "Vertices", [], "FaceColor", "none" );
set( ax(2), "YDir", "reverse" )
title( ax(2), "Projected Mesh" )
% 
ax(3) = nexttile( tl );
h(3) = imagesc( ax(3), [] );
title( ax(3), "Rastered Colors" )
% 
ax(4) = nexttile( tl );
h(4) = imagesc( ax(4), [] );
set( ax(4), "Colormap", flipud( gray ), "CLim", [1.5 8.5] )
title( ax(4), "Rastered Depths" )
% 
set( ax(2:4), "DataAspectRatio", [1 1 1], ...
    "XLim", [1 Camera.imageSize(1)], "YLim", [1 Camera.imageSize(2)], ...
    "XColor", "none", "YColor", "none" )
rng( 6 )
set( ax([1 3]), "Colormap", datasample( colorcube, size( faces, 1 ), 1 ), ...
    "CLim", [1 size( faces, 1 ) ] )

% set(ax,'XColor','k','YColor','k','XTick',[],'YTick',[],'Box','on')
% set( f, 'Units', 'pixels', 'InnerPosition', [0 0 723 249], ...
%     'Resize', 'off', 'ToolBar', 'none', 'Color', 'w' );
% savePath = fullfile( 'C:\Users\Abrahams George\Documents\Camera\figure1.avi' );
% vWrite = VideoWriter( savePath, 'Uncompressed AVI' );
% vWrite.FrameRate = 30;
% open( vWrite );
% for i = 1 : 128
%     frame = getframe( f );
%     writeVideo( vWrite, frame );
% end
% close( vWrite );

while isgraphics( f )
    rotation = rotx( 2 ) * rotz( 2 );
    Camera.t = Camera.t * rotation;
    Camera.R = Camera.R * rotation;
    [ verticesImg, facesImg, idsImg ] = ...
        world2image( Camera, vertices, faces );
    [ I, depthMap ] = rasterize( Camera.imageSize, verticesImg, facesImg, idsImg' );
    %
    rays = raycast( Camera, verticesImg(:,1:2) );
    props = PROJECTION_MATRIX.decompose;
    if ~isempty( verticesImg )
        verticesClipped = rays .* (verticesImg(:,3)./props.near) + Camera.t;
        set( h(1), "Faces", facesImg, "Vertices", verticesClipped, ...
            "FaceVertexCData", idsImg' )
    else
        set( h(1), "Faces", [], "Vertices", [], "FaceVertexCData", [] )
    end
    %
    set( h(2), 'Faces', facesImg, 'Vertices', verticesImg(:,1:2) )
    set( h(3), 'CData', I )
    set( h(4), 'CData', depthMap )
    drawnow
end