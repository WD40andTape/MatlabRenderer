function mustBeRightHanded( matrix, tolerance )
%MUSTBERIGHTHANDED Throw an error if matrices are not right-handed.
    arguments
        matrix { mustBeFloat }
        tolerance (1,1) { mustBeNumeric, mustBeNonNan } = 1e-4
    end
    try
        tf = all( isrighthanded( matrix, tolerance ) );
    catch causeME
        tf = false;
    end
    if ~tf
        id = "Validators:MatrixNotRightHanded";
        msg = sprintf( "Must be a valid rotation matrix and " + ...
            "right-handed within tolerance %s.", string( tolerance ) );
        baseME = MException( id, msg );
        if ~exist( "causeME", "var" )
            msg = "Basis vectors (matrix rows or columns) are not " + ...
                "right-handed.\nChange the handedness by:\n" + ...
                " -\tPermuting an even number of basis vectors.\n" + ...
                " -\tNegating an odd number of basis vectors.\n" + ...
                " -\tPerforming a reflection through a hyperplane.";
            causeME = MException( string.empty, msg );
        end
        baseME = addCause( baseME, causeME );
        throwAsCaller( baseME )
    end
end