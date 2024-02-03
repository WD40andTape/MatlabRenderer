function mustHaveFields( a, fields )
%MUSTHAVEFIELDS throws an error if the structure or class instance, a, does
% not contain all fields defined in the text array, fields.
    arguments
        a (1,1)
        fields { mustBeText }
    end
    fieldsOfA = fieldnames( a );
    aHasFields = ismember( fields, fieldsOfA );
    if ~all( aHasFields )
        id = "Validators:MissingCameraFields";
        msg = sprintf( ...
            "Must contain the following fields or properties:\n\t- %s", ...
            strjoin( fields(~aHasFields), "\n\t- " ) );
        throwAsCaller( MException( id, msg ) )
    end
end