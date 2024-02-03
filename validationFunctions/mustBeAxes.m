function mustBeAxes( x )
%MUSTBEAXES Throw an error if any X is not a valid graphics objects parent.
%   X must be an array of axes, group (hggroup), or transform 
%   (hgtransform) objects, and must not have been deleted (closed, 
%   cleared, etc).
    if ~isaxes( x )
        id = "Validators:InvalidAxesHandle";
        msg = "Must be handles to graphics objects " + ...
            "parents which have not been deleted.";
        throwAsCaller( MException( id, msg ) )
    end
end