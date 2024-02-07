function mustHaveFields( a, fields )
%MUSTHAVEFIELDS Throw an error if a does not have all specified fields.
% 
% SYNTAX
%   mustHaveFields( a, fields )
% 
% INPUTS
%   a        Scalar structure array or class instance.
%   fields   Required fields of a. String scalar, character vector, string 
%             array, or cell array of character vectors.
% 
    arguments
        a (1,1)
        fields { mustBeText }
    end
    aHasFields = ismember( fields, fieldnames( a ) );
    if ~all( aHasFields )
        id = "Validators:MissingFields";
        msg = sprintf( ...
            "Must contain the missing fields or properties:\n\t- %s", ...
            strjoin( fields(~aHasFields), "\n\t- " ) );
        throwAsCaller( MException( id, msg ) )
    end
end