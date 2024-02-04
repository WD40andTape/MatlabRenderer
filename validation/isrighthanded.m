function tf = isrighthanded( matrix, tolerance )
%ISRIGHTHANDED Check if rotation matrices are right-handed.
    arguments
        matrix { mustBeFloat }
        tolerance (1,1) { mustBeNumeric, mustBeNonNan } = 1e-4
    end
    mustBeOrthonormal( matrix, tolerance )
    n = size( matrix, 3 );
    tf = false( n, 1 );
    for i = 1 : n
        % Right-handed rotation matrices have a determinant of 1.
        matrixDet = det( matrix(:,:,i) );
        unitDiff = abs( matrixDet - 1 );
        if unitDiff < tolerance
            tf(i) = true;
        end
    end
end