function [ inside, barycentric ] = edgefcn( vertices, faces, points )
%EDGEFCN Test whether 2D points are within triangular faces.
% NOTE: You can test against many points against one face OR one point
% against many faces. Testing of many points against many faces is not
% supported.
%
% [ inside, barycentric ] = edgefcn( vertices, faces, points )
% 
% INPUTS
% - vertices     Nx2 matrix of vertices in image space. Vertices can be
%                inside or outside of the image bounds.
% - faces        Mx3 matrix of faces where each row indexes the
%                vertices of a triangle. Faces should be defined with
%                a clockwise winding.
% - points       Qx2 matrix of points to test. If multiple faces are 
%                given (M > 1), only one point can be tested (Q == 1).
% 
% OUTPUTS
% - inside       Mx1 boolean matrix. Where true, the point is within 
%                the respective face.
% - barycentric  Barycentric coordinate of image points.
% 
% NOTE: No top-left rule for overlapping edges is implemented.
    
    assert( size( faces, 1 ) == 1 || size( points, 1 ) == 1 )
    
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