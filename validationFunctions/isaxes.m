function tf = isaxes( x )
%ISAXES Check that all X are valid graphics object parents.
%   X must be an array of axes, group (hggroup), or transform 
%   (hgtransform) objects, and must not have been deleted (closed, 
%   cleared, etc).
    tf = isgraphics( x, "matlab.graphics.axis.Axes" ) || ...
         isgraphics( x, "matlab.graphics.primitive.Group" ) || ...
         isgraphics( x, "matlab.graphics.primitive.Transform" );
end