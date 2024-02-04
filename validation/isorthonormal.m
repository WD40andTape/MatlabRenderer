function tf = isorthonormal( matrix, tolerance )
%ISORTHONORMAL Check if matrices are orthonormal, aka orthogonal.
    arguments
        matrix { mustBeFloat }
        tolerance (1,1) { mustBeNumeric, mustBeNonNan } = 1e-4
    end
    sz = size( matrix );
    assert( numel( matrix ) > 1, ...
        "An empty matrix or scalar does not have a basis." )
    assert( sz(1) == sz(2), "Non-square matrices either have basis" + ...
        "vectors of different dimensions or insufficient basis " + ...
        "vectors to fully define the basis." )
    assert( all( ~isnan( matrix ) & isreal( matrix ), 'all' ), ...
        "Orthonormal matrices cannot contain NaN elements or " + ...
        "imaginary parts." )
    % Matrix is orthonormal if multiplication of itself with its 
    % transpose gives the identity matrix.
    mxmT = pagemtimes( matrix, "none", matrix, "transpose" );
    eyeDiff = abs( mxmT - eye( sz(1) ) );
    tf = squeeze( all( eyeDiff < tolerance, [1 2] ) );
end