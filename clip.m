function [ vertices, connectivity, ids ] = clip( vertices, connectivity )
%CLIP Clip faces/edges/vertices in the clip space of the graphics pipeline.
% 
% Implements clipping for vertices, edges/lines (with the Cohen-Sutherland 
% algorithm), and triangular faces/meshes (with the Sutherland-Hodgman 
% algorithm) in the clip space of the rendering pipeline. The clip space 
% occurs after the projection matrix is applied, but before the perspective 
% divide (normalization).
%
% SYNTAX
%   [ vertices, connectivity, id ] = clip( vertices )
%   [ vertices, connectivity, id ] = clip( vertices, connectivity )
%
% INPUTS
%   vertices      Nx4 array, where each row represents the homogenous
%                  coordinates (X,Y,Z,W) of a vertex in 4D clip space. We 
%                  use the convention that the clip space is defined by 
%                  -W≤X≤W, -W≤Y≤W, -W≤Z≤W. The alternative convention 
%                  defines 0≤Z≤W.
%   connectivity  (OPTIONAL) Mx1, Mx2 or Mx3 array where each row indexes 
%                  the vertices of a vertex, edge, or face primitive, 
%                  respectively. Faces need to be defined with a clockwise 
%                  winding. Default: Mx1 array defining unlinked vertices.
% OUTPUTS
%   vertices      Same definition as input. Vertices may be added or 
%                  removed during clipping.
%   connectivity  Same definition and order as input. Primitives completely 
%                  outside of the viewing frustum are removed. If the 
%                  primitives are triangles, then the output may contain 
%                  additional new triangles created in the process.
%   ids           Integer column vector which references the row indices of 
%                  the input connectivity array. The IDs of deleted 
%                  primitives will be removed. The IDs of new triangles 
%                  created by splitting existing triangles will share the 
%                  original ID.
% 
% Created in 2022b. Compatible with 2019b and later. Compatible with all 
%  platforms. Please cite George Abrahams 
%  https://github.com/WD40andTape/MatlabRenderer.

% Published under MIT License (see LICENSE.txt).
% Copyright (c) 2024 George Abrahams.
%  - https://github.com/WD40andTape/
%  - https://www.linkedin.com/in/georgeabrahams/
%  - https://scholar.google.com/citations?user=T_xxZLwAAAAJ

    arguments
        vertices (:,4) { mustBeNonempty, mustBeNumeric, mustBeReal, ...
            mustBeNonNan, mustBeFinite }
        connectivity { mustBeNonempty, mustBeInteger, ...
            mustBe3DorLower } = ( 1 : size( vertices, 1 ) )'
    end
    
    % order = 1 for vertices, 2 for lines, 3 for triangles (faces).
    order = size( connectivity, 2 );
    
    % verticesPerPrimitive is in the format numPrimitives-by-4-by-order.
    verticesPerPrimitive = vertices( connectivity, : )';
    verticesPerPrimitive = reshape( verticesPerPrimitive, 4, [], order );
    verticesPerPrimitive = permute( verticesPerPrimitive, [2 1 3] );
    % outcodes is in the format numPrimitives-by-6-by-order. It is false if 
    % the point is within each of the boundaries, 
    % [left right bottom top near far], or true otherwise.
    outcodes = computeCodes( verticesPerPrimitive );
    % outside = the primitive is completely outside of the viewing frustum.
    outside = any( all( outcodes, 3 ), 2 );
    % Exclude primitives containing points with zero w, i.e. at infinity
    outside = outside | any( verticesPerPrimitive(:,4,:) == 0, 3 );
    % inside = the primitive is completely within the viewing frustum.
    inside = ~any( outcodes, [2 3] );
    % clipped = part of the primitive *may* be within the viewing frustum.
    clipped = ~(inside | outside);
    
    % Extract the primitives to be clipped. This duplicates the vertices so
    % that clipping of one primitive doesn't affect the others.
    % clippedIds refers to the linear indices of the connectivity array.
    clippedIds = find( clipped );
    % verticesPerClipped is in the format order-by-4-by-numPrimitives.
    verticesPerClipped = vertices( connectivity( clipped, : )', : )';
    verticesPerClipped = reshape( verticesPerClipped, 4, order, [] );
    verticesPerClipped = permute( verticesPerClipped, [2 1 3] );
    % Keep original primitives that are completely inside the viewing 
    % frustum, as these won't change during clipping.
    connectivity = connectivity(inside,:);
    ids = find( inside );
    % Delete unused vertices and update the connectivity array.
    [ usedVertices, ~, connectivity ] = unique( connectivity );
    connectivity = reshape( connectivity, [], order );
    vertices = vertices(usedVertices,:);
    % Exit early for trivial cases.
    if order == 1 || all( inside )
        return
    end

    % Construct polygons for clipping.
    if order == 2
        % A clipped line remains a line, i.e., contains 2 vertices.
        maxVertices = 2;
    else % order == 3
        % The polygon produced from clipping a triangle with a cube will 
        % have between 3 and 6 vertices/sides.
        maxVertices = 6;
    end
    nClipped = size( verticesPerClipped, 3 );
    % Produce a clipped polygon by clipping each primitive's edges against 
    % each of the boundaries, in the order: left, right, bottom, top, near,
    % far.
    region = [1 1 2 2 3 3];
    sgn = [-1 1 -1 1 -1 1];
    polygonsCurrent = nan( maxVertices, 4, nClipped );
    polygonsCurrent(1:order,:,:) = verticesPerClipped;
    nVerticesCurrent = ones( 1, nClipped ) .* order;
    for i = 1 : numel( region ) % For each boundary.
        polygonsUpdated = nan( maxVertices, 4, nClipped );
        nVerticesUpdated = zeros( 1, nClipped );
        for j = 1 : nClipped % For each primitive to be clipped.
            outcodes = computeCodes( polygonsCurrent(:,:,j) );
            for id0 = 1 : nVerticesCurrent(j) % For each edge.
                isP0in = ~outcodes(id0,i);
                if isP0in
                    polygonsUpdated(nVerticesUpdated(j)+1,:,j) = ...
                        polygonsCurrent(id0,:,j);
                    nVerticesUpdated(j) = nVerticesUpdated(j) + 1;
                end
                id1 = mod( id0, nVerticesCurrent(j) ) + 1;
                isP1in = ~outcodes(id1,i);
                % For edges, only add the intersection in one direction.
                addIntersection = (order>2 && xor( isP0in, isP1in )) ...
                    || (order==2 && isP0in && ~isP1in);
                if addIntersection
                    p0 = polygonsCurrent(id0,:,j);
                    p1 = polygonsCurrent(id1,:,j);
                    diff1 = sgn( i ) * p0(:,4) - p0(:,region(i));
                    diff2 = sgn( i ) * p1(:,4) - p1(:,region(i));
                    t = diff1 ./ (diff1 - diff2);
                    intersection = p0 + t .* ( p1 - p0 );
                    % Set the intersection to be exactly on the plane,
                    % avoiding floating-point precision issues at the edges
                    % of the image.
                    intersection(region(i)) = sgn( i ) .* intersection(4);
                    polygonsUpdated(nVerticesUpdated(j)+1,:,j) = ...
                        intersection;
                    nVerticesUpdated(j) = nVerticesUpdated(j) + 1;
                end
            end
        end
        polygonsCurrent = polygonsUpdated;
        nVerticesCurrent = nVerticesUpdated;
    end
    % Remove primitives which didn't cross the frustum at all 
    % (non-trivial culling).
    inside = nVerticesUpdated >= order;
    nClipped = sum( inside );
    polygonsUpdated = polygonsUpdated(:,:,inside);
    clippedIds = clippedIds(inside);
    nVerticesUpdated = nVerticesUpdated(inside);
    
    % Construct the output.
    if order == 2
        newEdges = ( 1 : nClipped * 2 ) + size( vertices, 1 );
        newEdges = reshape( newEdges, 2, nClipped )';
        connectivity = [ connectivity; newEdges ];
        ids = [ ids; clippedIds ];
        newVertices = permute( polygonsUpdated, [2 1 3] );
        newVertices = reshape( newVertices, 4, 2 * nClipped )';
        vertices = [ vertices; newVertices ];
    else % order == 3
        % Tessellate the polygons from clipping (fan triangulation).
        for i = 1 : size( polygonsUpdated, 3 )
            nNewTriangles = nVerticesUpdated(i)-2;
            if nNewTriangles < 1
                continue
            end
            newFaces = ones( nNewTriangles, 3 );
            newFaces(:,2) = 2 : nVerticesUpdated(i) - 1;
            newFaces(:,3) = 3 : nVerticesUpdated(i);
            newFaces = newFaces + size( vertices, 1 );
            connectivity = [ connectivity; newFaces ];
            ids = [ ids; clippedIds(i) .* ones( nNewTriangles, 1 ) ];
            newVertices = polygonsUpdated(1:nVerticesUpdated(i),:,i);
            vertices = [ vertices; newVertices ];
        end
    end
    
end

%% Helper functions.

function outcodes = computeCodes( p )

    % p is provided in the format numPrimitives-by-4-by-order.
    % Use a tolerance to avoid floating point inconsistencies
    % at the edges of the image.
    tol = 1e-12;
    % outcodes is in the format numPrimitives-by-6-by-order. It is false if 
    % the point is within each of the boundaries, 
    % [left right bottom top near far], or true otherwise.
    outcodes = true( size(p,1), 6, size(p,3) );
    outcodes(:,1,:) = p(:,1,:)+p(:,4,:) < -tol;
    outcodes(:,2,:) = p(:,1,:)-p(:,4,:) > tol;
    outcodes(:,3,:) = p(:,2,:)+p(:,4,:) < -tol;
    outcodes(:,4,:) = p(:,2,:)-p(:,4,:) > tol;
    outcodes(:,5,:) = p(:,3,:)+p(:,4,:) < -tol;
    outcodes(:,6,:) = p(:,3,:)-p(:,4,:) > tol;
        
end

%% Validation functions.

function mustBe3DorLower( a )
%MUSTBE3DORLOWER throws an error if the size of the 2nd dimension of a is 
% more than 3, i.e., a must represent points, lines, or triangles.
    if size( a, 2 ) > 3
        id = "clip:Validators:InvalidPrimitives";
        msg = "size( x, 2 ) must be <= 3, representing points, " + ...
            "lines, or triangles.";
        throwAsCaller( MException( id, msg ) )
    end
end