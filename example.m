addpath( genpath( pwd ) ), clearvars, close all

PROJECTION_MATRIX = ProjectionMatrix( deg2rad(55), 1, 0.1 );
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
Cam = Camera( PROJECTION_MATRIX, IMAGE_SIZE, ...
    CAMERA_TRANSLATION, CAMERA_ROTATION );

rotation = rotz( 180 ) * rotx( -135 ) * rotz( 0 ); % -135, 0
Cam.t = Cam.t * rotation;
Cam.R = Cam.R * rotation;

f = figure;
tl = tiledlayout( 2, 3, TileSpacing="tight", Padding="tight" );
% 
ax(1) = nexttile( tl );
h(1) = patch( ax(1), "Faces", faces, "Vertices", vertices, ...
    "CData", 1 : size( faces, 1 ), "FaceColor", "flat", "EdgeColor", "none" );
material( h(1), "dull" )
Cam.plotcamera( ax(1), 0.75 )
Cam.plotframe( ax(1), 0.75, "" )
tRange = [ -norm( CAMERA_TRANSLATION ), norm( CAMERA_TRANSLATION ) ];
set( ax(1), "DataAspectRatio", [1 1 1], "View", [-37.5 30], ...
    "XLim", tRange, "YLim", tRange, "ZLim", tRange, ...
    "XTick", [], "YTick", [], "ZTick", [], "Box", "on" )
camlight( ax(1), 'right' )
title( ax(1), "Scene and Camera" )
% 
ax(2) = nexttile( tl );
h(2) = patch( ax(2), "Faces", faces, "Vertices", vertices, ...
    "CData", 1 : size( faces, 1 ), "FaceColor", "flat", "EdgeColor", "none" );
material( h(2), "dull" )
Cam.plotcamera( ax(2), 0.75 )
Cam.plotfov( ax(2), 4.7 )
set( ax(2), "DataAspectRatio", [1 1 1], "View", [-37.5 30], ...
    "XLim", tRange, "YLim", tRange, "ZLim", tRange, ...
    "XTick", [], "YTick", [], "ZTick", [], "Box", "on" )
camlight( ax(2), 'right' )
title( ax(2), "Face Culling and Clipping" )
% 
ax(3) = nexttile( tl );
h(3) = patch( ax(3), "Faces", [], "Vertices", [], "FaceColor", "none" );
set( ax(3), "YDir", "reverse" )
title( ax(3), "Projected Mesh" )
% 
ax(4) = nexttile( tl );
h(4) = imagesc( ax(4), [] );
title( ax(4), "Rastered Colors" )
% 
ax(5) = nexttile( tl );
h(5) = imagesc( ax(5), [] );
set( ax(5), "Colormap", flipud( gray ), "CLim", [1.5 8.5] )
title( ax(5), "Rastered Depths" )
% 
set( ax(3:5), "DataAspectRatio", [1 1 1], ...
    "XLim", [1 Cam.imageSize(1)], "YLim", [1 Cam.imageSize(2)], ...
    "XColor", "none", "YColor", "none" )
rng( 6 )
set( ax([1 2 4]), "Colormap", datasample( colorcube, size( faces, 1 ), 1 ), ...
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
    Cam.t = Cam.t * rotation;
    Cam.R = Cam.R * rotation;
    [ verticesImg, facesImg, idsImg ] = ...
        world2image( Cam, vertices, faces );
    [ I, depthMap ] = rasterize( Cam.imageSize, verticesImg, facesImg, idsImg' );
    %
    rays = raycast( Cam, verticesImg(:,1:2) );
    props = PROJECTION_MATRIX.decompose;
    if ~isempty( verticesImg )
        verticesClipped = rays .* (verticesImg(:,3)./props.near) + Cam.t;
        set( h(2), "Faces", facesImg, "Vertices", verticesClipped, ...
            "FaceVertexCData", idsImg' )
    else
        set( h(2), "Faces", [], "Vertices", [], "FaceVertexCData", [] )
    end
    %
    set( h(3), 'Faces', facesImg, 'Vertices', verticesImg(:,1:2) )
    set( h(4), 'CData', I )
    set( h(5), 'CData', depthMap )
    drawnow
end