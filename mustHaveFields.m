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
% Created in 2022b. Compatible with 2020b and later. Compatible with all 
%  platforms. Please cite George Abrahams 
%  https://github.com/WD40andTape/MatlabRenderer.

% Published under MIT License (see LICENSE.txt).
% Copyright (c) 2024 George Abrahams.
%  - https://github.com/WD40andTape/
%  - https://www.linkedin.com/in/georgeabrahams/
%  - https://scholar.google.com/citations?user=T_xxZLwAAAAJ

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