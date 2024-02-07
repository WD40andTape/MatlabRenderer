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
%   vertices     Nx3 matrix of vertices, where N is the number of vertices, 
%                 and each vertex is in the form [X Y Z]. X and Y are in 
%                 image space, i.e. measured in pixels. Z is in world 
%                 space, i.e., the distance from the camera along the 
%                 Z-dimension, measured in world units. Vertices can be
%                 inside or outside of the image bounds.
%   faces        Mx3 matrix of faces, where M is the number of faces and 
%                 each row indexes the 3 vertices of a triangle. Faces 
%                 should be defined with a clockwise winding. Points within 
%                 faces with a counterclockwise winding will always return 
%                 false, as these are considered to be backfaces.
%   points       Qx2 matrix of points to test. If multiple faces are 
%                 given (M > 1), only one point can be tested (Q == 1). The
%                 form of points should match vertices, i.e., either [x y]
%                 or [y x], although switching the axes inverts the face 
%                 windings.
% 
% OUTPUTS
%   inside       Mx1 boolean matrix. Where true, the point is within 
%                 the respective face.
%   barycentric  Barycentric coordinate of image points.
% 
% Be aware that no top-left rule for rendering overlapping edges is 
% implemented. This can cause a dark edge to appear at the border between 
% semi-transparent faces.
%
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