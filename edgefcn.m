function [ inside, barycentric ] = edgefcn( vertices, faces, points )
%EDGEFCN Test whether 2D points are within triangular faces.
% edgefcn supports testing many points against one face OR one point
% against many faces. Testing of many points against many faces is not 
% possible.
%
% SYNTAX
%   [ inside, barycentric ] = edgefcn( vertices, faces, points )
% 
% INPUTS
%   vertices     Vx2 array of vertices, where V is the number of vertices, 
%                 and each vertex is in the form [X Y] in the image space 
%                 coordiante system and are therefore measured in pixels.
%                 Vertices can be inside or outside of the image bounds.
%   faces        Fx3 array of faces, where F is the number of faces and 
%                 each row indexes the 3 vertices of a triangle. Faces 
%                 should be defined with a clockwise winding. Points within 
%                 faces with a counterclockwise winding will always return 
%                 false, as these are considered to be backfaces.
%   points       Px2 array of points to test. If multiple faces are 
%                 given (F > 1), only one point can be tested (P == 1). The
%                 form of points should match vertices, i.e., either [X Y]
%                 or [Y X], although switching the axes inverts the face 
%                 windings.
% 
% OUTPUTS
%   inside       If many points are tested again one face (P > 1, F == 1), 
%                 inside is a Px1 boolean array. Where true, the 
%                 respective point is within the given face. If one point 
%                 is tested against many faces (P == 1, F > 1), inside is 
%                 an Fx1 boolean array. Where true, the given point is 
%                 within the respective face.
%   barycentric  If many points are tested again one face (P > 1, F == 1), 
%                 barycentric is a Px3 numeric array, containing the 
%                 barycentric coordinate of each point with respect to the 
%                 given face. If one point is tested against many faces 
%                 (P == 1, F > 1), barycentric is an Fx3 numeric array, 
%                 containing the barycentric coordinates of the given point 
%                 with respect to each face.
% 
% Be aware that no top-left rule for rendering overlapping edges is 
% implemented. This can cause a dark edge to appear at the border between 
% semi-transparent faces.
% 
% Created in 2022b. Compatible with 2007a and later. Compatible with all 
%  platforms. Please cite George Abrahams 
%  https://github.com/WD40andTape/MatlabRenderer.

% Published under MIT License (see LICENSE.txt).
% Copyright (c) 2024 George Abrahams.
%  - https://github.com/WD40andTape/
%  - https://www.linkedin.com/in/georgeabrahams/
%  - https://scholar.google.com/citations?user=T_xxZLwAAAAJ

    assert( size( faces, 1 ) == 1 || size( points, 1 ) == 1, ...
        "edgefcn supports testing many points against one face OR " + ...
        "one point against many faces. Testing of many points " + ...
        "against many faces is not possible." )
    
    V1 = vertices(faces(:,1),:);
    V2 = vertices(faces(:,2),:);
    V3 = vertices(faces(:,3),:);
    w1 = ( points(:,1) - V2(:,1) ) .* ( V3(:,2) - V2(:,2) ) - ...
        ( points(:,2) - V2(:,2) ) .* ( V3(:,1) - V2(:,1) );
    w2 = ( points(:,1) - V3(:,1) ) .* ( V1(:,2) - V3(:,2) ) - ...
        ( points(:,2) - V3(:,2) ) .* ( V1(:,1) - V3(:,1) );
    w3 = ( points(:,1) - V1(:,1) ) .* ( V2(:,2) - V1(:,2) ) - ...
        ( points(:,2) - V1(:,2) ) .* ( V2(:,1) - V1(:,1) );
    inside = w1 >= 0 & w2 >= 0 & w3 >= 0;
    if nargout > 1
        area = ( V3(:,1) - V1(:,1) ) .* ( V2(:,2) - V1(:,2) ) - ...
            ( V3(:,2) - V1(:,2) ) .* ( V2(:,1) - V1(:,1) );
        barycentric = [ w1, w2, w3 ] ./ area;
    end
end