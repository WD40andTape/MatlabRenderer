function mustBeOrthonormal( matrix, tolerance )
%MUSTBEORTHONORMAL Throw an error if matrices are not orthonormal.
    arguments
        matrix { mustBeFloat }
        tolerance (1,1) { mustBeNumeric, mustBeNonNan } = 1e-4
    end
    try
        tf = isorthonormal( matrix, tolerance );
    catch causeME
        tf = false;
    end
    if ~tf
        id = "Validators:MatrixNotOrthonormal";
        msg = sprintf( ...
            "Must be orthonormal within tolerance %s, i.e.,\n" + ...
            " -\tThe matrices must be square and at least 2-by-2.\n" + ...
            " -\tTheir basis vectors must be perpendicular and have " + ...
                "a Euclidean length equal to 1.\n" + ...
            " -\tAll elements must be real and non-NaN.", ...
            string( tolerance ) );
        baseME = MException( id, msg );
        if ~exist( "causeME", "var" )
            causeME = MException( string.empty, "Basis vectors are " + ...
                "either not perpendicular or not unit length." );
        end
        baseME = addCause( baseME, causeME );
        throwAsCaller( baseME )
    end
end