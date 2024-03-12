classdef ProjectionMatrix < double
%PROJECTIONMATRIX Build and inspect a camera projection matrix.
%
% VALUE
%   The value of a ProjectionMatrix object is a 4-by-4 perspective or 
%   orthographic projection matrix. It is row-major, right-handed, and the 
%   camera is aligned along the world coordinate system's negative Z-axis. 
%   Row-major order means that points are represented by row vectors and 
%   projected points are given by pre-multiplication, i.e., 
%   points * matrix. The near and far clip planes correspond to Z 
%   normalized device coordinates of -1 and +1 respectively.
%
%   ProjectionMatrix is a subclass of the built-in type double. A 
%   ProjectionMatrix object (obj) therefore functions as if it were a 
%   variable containing a 4-by-4 array. For example, obj(2,2) returns the 
%   value of the (2,2) element of the projection matrix. obj can therefore 
%   be passed directly to functions which take a 4-by-4 numeric array as 
%   input.
%   
% METHODS
%   Constructor
%       Build a perspective or orthographic camera projection matrix.
% 
%       A projection matrix can be built either with the camera's 
%       field-of-view and aspect ratio, by defining the frustum coordinates 
%       directly, or by converting from a camera intrinsic matrix.
%
%       For detailed documentation, use the command:
%           <a href="matlab: doc ProjectionMatrix.ProjectionMatrix"
%               >doc ProjectionMatrix.ProjectionMatrix</a>
%   decompose
%       Extract properties of the camera's view frustum.
%
%       The given properties are: the position of the near- and 
%       far-clipping planes; the left, right, bottom, and top viewing 
%       frustum coordinates; the field-of-view in the horizontal and 
%       vertical directions, and the aspect ratio of the field-of-view.
%
%       For detailed documentation, use the command:
%           <a href="matlab: doc ProjectionMatrix.decompose"
%               >doc ProjectionMatrix.decompose</a>
% 
% EXAMPLE: Please see the file 'example.m'.
% 
% Created in 2022b. Compatible with 2022a and later. Compatible with all 
%  platforms. Please cite George Abrahams 
%  https://github.com/WD40andTape/MatlabRenderer.

% Published under MIT License (see LICENSE.txt).
% Copyright (c) 2024 George Abrahams.
%  - https://github.com/WD40andTape/
%  - https://www.linkedin.com/in/georgeabrahams/
%  - https://scholar.google.com/citations?user=T_xxZLwAAAAJ

    methods(Access=public)
        function obj = ProjectionMatrix( varargin )
            %PROJECTIONMATRIX Build a camera projection matrix.
            %
            % SYNTAX
            %   For a perspective or orthographic projection:
            %     obj = ProjectionMatrix(matrix)
            %   For a perspective projection:
            %     obj = ProjectionMatrix()
            %     obj = ProjectionMatrix(fovY, aspectRatio, near)
            %     obj = ProjectionMatrix(fovY, aspectRatio, near, far)
            %     obj = ProjectionMatrix(intrinsics, imageSize, near)
            %     obj = ProjectionMatrix(intrinsics, imageSize, near, far)
            %     obj = ProjectionMatrix(left, right, bottom, top, ...
            %         near, "perspective")
            %     obj = ProjectionMatrix(left, right, bottom, top, ...
            %         near, far, "perspective")
            %   For an orthographic projection:
            %     obj = ProjectionMatrix(left, right, bottom, top, ...
            %         near, far, "orthographic")
            %
            % INPUTS
            %   matrix       4-by-4 perspective or orthographic projection 
            %                 matrix. matrix must be row-major and 
            %                 right-handed. The camera is aligned along 
            %                 the world's negative Z-axis. The near and far 
            %                 clip planes must correspond to Z normalized 
            %                 device coordinates of -1 and +1 respectively 
            %                 (OpenGL convention), as opposed to 0 and +1 
            %                 respectively (Direct3D convention). A 
            %                 row-major perspective projection matrix will 
            %                 have 0s in elements (1,3) and (2,3). A 
            %                 row-major orthographic projection matrix will 
            %                 have 0s in elements (1,4), (2,4), and (3,4). 
            %                 Convert between row- and column-major order 
            %                 by taking the transpose, i.e, 
            %                 matrix = matrix'. For row-major matrices, 
            %                 convert between handedness by negating row 1, 
            %                 2, or 3 (typically the 3rd row, the Z-axis), 
            %                 e.g., matrix(3,:) = -matrix(3,:).
            %   fovY         The field-of-view, in radians, in the Y 
            %                 (vertical) direction. Defined as the angle 
            %                 between the pixel centers of the top and 
            %                 bottom rows of pixels.
            %   aspectRatio  The aspect ratio of the viewing frustum, which 
            %                 establishes the field-of-view in the X 
            %                 direction. Given as the ratio of X to Y, 
            %                 i.e., frustum width / height. For a given 
            %                 image (viewport) aspect ratio, calculate the
            %                 aspect ratio of the frustum as follows: 
            %                 (imageWidth - 1) / (imageHeight - 1).
            %   intrinsics   3-by-3 MATLAB-style camera intrinsic matrix. 
            %                 Must be in the form, 
            %                 [fx s cx; 0 fy cy; 0 0 1], where cx and cy 
            %                 are the principal point in pixels, fx and fy 
            %                 are the focal lengths in pixels, and s is the 
            %                 skew parameter. By MATLAB convention, the 
            %                 upper-left pixel center has the coordinate 
            %                 (1,1). Therefore, for a symmetrical camera, 
            %                 cx = imageWidth / 2 + 0.5, and similarly for 
            %                 cy. Note that projection matrices cannot 
            %                 represent axes skew, if it exists in the 
            %                 intrinsic matrix.
            %   imageSize    Camera resolution. 2-element integer vector, 
            %                 in the form [width height].
            %   near         The distance from the optical center to the 
            %                 near-clipping plane, in world units, measured 
            %                 along the camera's line-of-sight (local 
            %                 Z-axis). Objects closer than near are not 
            %                 rendered. near must be positive and finite.
            %   far          The distance to the far-clipping plane, in 
            %                 world units. Objects further than far are not 
            %                 rendered. far must be positive and may be 
            %                 infinite. For othographic projections, far 
            %                 must be finite. By default, far is infinite 
            %                 (Inf).
            %   left         Position of the left camera frustum coordinate
            %                 on the near-clipping plane, in world units, 
            %                 measured along the camera's X-axis. Together 
            %                 with right, left determines the width of the 
            %                 image plane, and therefore the field-of-view 
            %                 in the X (horizontal) direction.
            %   right        Position of the right camera frustum 
            %                 coordinate, in world units. Right must be 
            %                 greater than left.
            %   bottom       Position of the bottom camera frustum 
            %                 coordinate, in world units, measured along 
            %                 the camera's Y-axis. Together with top, 
            %                 bottom determines the height of the image 
            %                 plane, and therefore the field-of-view in the 
            %                 Y (vertical) direction.
            %   top          Position of the top camera frustum coordinate, 
            %                 in world units. top must be greater than 
            %                 bottom.
            %
            %   When ProjectionMatrix is called without any arguments, a
            %   default projection matrix is provided. The default is a 
            %   perspective projection matrix with an aspect ratio of 1, a 
            %   90-degree field-of-view, the near-clipping plane at 0.5, 
            %   and the far clipping-plane at infinity.
            %
            % OUTPUTS
            %   obj          For documentation, use the command:
            %                   doc ProjectionMatrix
            % 
            if nargin == 0
                % Use a default projection matrix.
                data = [1 0 0 0; 0 1 0 0; 0 0 -1 -1; 0 0 -1 0];
                far = NaN; % Do not update far plane.
            elseif nargin == 1
                % Use the provided projection matrix.
                ProjectionMatrix.validateprojection( varargin{1} )
                if ( varargin{1}(16) == 0 && ... % Perspective.
                        ~isequal( varargin{1}([9 10 15]), [0 0 -1] ) && ...
                        isequal( varargin{1}([3 7 12]), [0 0 -1] ) ) ...
                    || ( varargin{1}(16) == 1 && ... % Orthographic.
                        ~isequal( varargin{1}(13:15), [0 0 0] ) && ...
                        isequal( varargin{1}([4 7 12]), [0 0 0] ) )
                    warning( "Detected column-major projection " + ...
                        "matrix, when it should have been " + ...
                        "row-major. Transpose the matrix to remove " + ...
                        "this warning." )
                    varargin{1} = varargin{1}';
                end
                data = varargin{1};
                far = NaN; % Do not update far plane.
            elseif isscalar( varargin{1} ) && (nargin == 3 || nargin == 4)
                % Build projection matrix from the field-of-view in the 
                % Y direction, the aspect ratio of the image, and the Z 
                % position of the near and optionally far frustum planes.
                if nargin == 3
                    varargin{4} = Inf;
                end
                ProjectionMatrix.validatecameraprops( varargin{:} )
                [ fovY, aspectRatio, near, far ] = varargin{:};
                % The projection matrix is derived from the following 
                % geometric definitions:
                %  top = tan( fovY / 2 ) * near;
                %  bottom = -top;
                %  right = top * aspectRatio;
                %  left = -right;
                data = zeros( 4 );
                data(1,1) = 1 / (aspectRatio * tan( fovY / 2 ));
                data(2,2) = 1 / tan( fovY / 2 );
                data(3,4) = -1;
                data(3,3) = -(far + near) / (far - near);
                data(4,3) = -(2 * far * near) / (far - near);
            elseif nargin == 3 || nargin == 4 % ~isscalar( varargin{1} )
                % Convert from MATLAB-style camera intrinsic matrix.
                if nargin == 3
                    varargin{4} = Inf;
                end
                ProjectionMatrix.validateintrinsics( varargin{:} )
                [ intrinsics, imageSize, near, far ] = varargin{:};
                if ~isequal( intrinsics([2 3 6 9]), [0 0 0 1] ) && ...
                        isequal( intrinsics([4 7 8 9]), [0 0 0 1] )
                    warning( "Detected column-major intrinsic " + ...
                        "matrix, when it should have been " + ...
                        "row-major. Transpose the matrix to remove " + ...
                        "this warning." )
                    intrinsics = intrinsics';
                end
                focalLength = [ intrinsics(1,1), intrinsics(2,2) ];
                principalPoint = [ intrinsics(1,3), intrinsics(2,3) ];
                if intrinsics(1,2) ~= 0
                    warning( "The provided intrinsic matrix " + ...
                        "contains non-zero axes skew at element " + ...
                        "(1,2), which cannot be represented by a " + ...
                        "projection matrix." )
                end
                % For the intrinsic matrix, the ratio of the focal length 
                % and image size (offset by the principal point), both 
                % measured in pixels, define the boundaries of the 
                % viewport. For the projection matrix, the position of the 
                % near clipping-plane is equivalent to the focal length, 
                % allowing us to derive a conversion. The viewport defined 
                % by the intrinsic matrix is geometrically equivalent to 
                % the planes of the viewing frustum, as follows:
                %   left = ((-cx+1) / fx) * near;
                %   right = ((w-cx) / fx) * near;
                %   top = ((cy-1) / fy) * near;
                %   bottom = ((cy-h) / fy) * near;
                % These can therefore be used to derive the equivalent 
                % projection matrix. Note the following details about the 
                % geometric conversion:
                % - The Y-axis of the image coordinates are inverted as 
                %   compared to the camera coordinates, i.e., the 
                %   Y-coordinate increases further down the image.
                % - The top and left frustum planes are coincident with the 
                %   upper-left pixel center, while the bottom and right 
                %   frustum planes are coincident with the lower-right 
                %   pixel center.
                % - MATLAB convention uses a spatial coordinate system with 
                %   the upper-left pixel center at (1,1). Therefore, for a 
                %   symmetrical camera, the principal point is given by 
                %   cx = imageWidth / 2 + 0.5, and similarly for cy.
                data = zeros( 4 );
                data(1,1) = 2 * focalLength(1) / (imageSize(1) - 1);
                data(2,2) = 2 * focalLength(2) / (imageSize(2) - 1);
                data(3,1) = (-2 * principalPoint(1) + imageSize(1) + 1) ...
                    / (imageSize(1) - 1);
                data(3,2) = (2 * principalPoint(2) - imageSize(2) - 1) ...
                    / (imageSize(2) - 1);
                data(3,4) = -1;
                data(3,3) = -(far + near) / (far - near);
                data(4,3) = -(2 * far * near) / (far - near);
            elseif nargin >= 5 && nargin <= 7
                % Build projection matrix from the position of the 
                % frustum's planes.
                if nargin == 5
                  % ProjectionMatrix(left, right, bottom, top, near)
                  varargin(6:7) = { Inf, "perspective" };
                elseif nargin == 6
                  if isnumeric( varargin{6} )
                      % ProjectionMatrix(left, right, bottom, top, near, far)
                      varargin{7} = "perspective";
                  else
                      % ProjectionMatrix(left, right, bottom, top, near, type)
                      varargin(6:7) = { Inf, varargin{6} };
                  end
                end
                ProjectionMatrix.validatefrustum( varargin{:} )
                [left, right, bottom, top, near, far, type] = varargin{:};
                if strncmpi( type, "perspective", 1 )
                    data = zeros( 4 );
                    data(1,1) = 2 * near / (right - left);
                    data(2,2) = 2 * near / (top - bottom);
                    data(3,1) = (right + left) / (right - left);
                    data(3,2) = (top + bottom) / (top - bottom);
                    data(3,4) = -1;
                    data(3,3) = -(far + near) / (far - near);
                    data(4,3) = -(2 * far * near) / (far - near);
                else % type == "orthographic"
                    data = eye( 4 );
                    data(1,1) = 2 / (right - left);
                    data(2,2) = 2 / (top - bottom);
                    data(3,3) = -2 / (far - near);
                    data(4,1) = -(right + left) / (right - left);
                    data(4,2) = -(top + bottom) / (top - bottom);
                    data(4,3) = -(far + near) / (far - near);
                end
            else
                id = "ProjectionMatrix:WrongNumberOfInputs";
                msg = "ProjectionMatrix was called with the wrong " + ...
                    "number of inputs. Please check the class syntax.";
                throwAsCaller( MException( id, msg ) )
            end
            % Handle far plane at infinity (for perspective projection).
            if isinf( far )
                % For an alternative method, see slide 15 of: 
                %  https://www.terathon.com/gdc07_lengyel.pdf
                data(3,3) = -1;
                data(4,3) = -2 * near;
            end
            % Store data in the superclass.
            obj = obj@double( data );
        end
        function props = decompose( obj )
            %DECOMPOSE Extract properties of the camera's view frustum.
            %
            % SYNTAX
            %   props = obj.decompose()
            %
            % OUTPUTS
            %   props   Structure array containing:
            %               left         Position of the left camera 
            %                             frustum coordinate on the 
            %                             near-clipping plane, in world 
            %                             units, measured along the 
            %                             camera's X-axis.
            %               right        Position of the right frustum 
            %                             coordinate, in world units.
            %               bottom       Position of the bottom frustum 
            %                             coordinate, in world units, 
            %                             measured along the camera's 
            %                             Y-axis.
            %               top          Position of the top frustum 
            %                             coordinate, in world units.
            %               near         The distance from the optical 
            %                             center to the near-clipping plane, 
            %                             in world units, measured along the 
            %                             camera's line-of-sight (local 
            %                             Z-axis).
            %               aspectRatio  The aspect ratio of the viewing 
            %                             frustum. Given as the ratio 
            %                             of X to Y, i.e., 
            %                             frustum width / height. This will 
            %                             almost identical to the aspect 
            %                             ratio of the final rastered 
            %                             image.
            %               fovX         The field-of-view, in radians, in 
            %                             the X (horizontal) direction. 
            %                             Defined as the angle between the 
            %                             pixel centers of the leftmost and
            %                             rightmost columns of pixels. NaN 
            %                             for orthographic projection 
            %                             matrices.
            %               fovY         The field-of-view, in radians, 
            %                             in the Y (vertical) direction. 
            %                             Defined as the angle between the 
            %                             pixel centers of the top and 
            %                             bottom rows of pixels. NaN for 
            %                             orthographic projection matrices.
            %
            if obj(4,4) == 0
                % Perspective projection matrix.
                props.near = obj(4,3) / ( obj(3,3) - 1 );
                if obj(3,3) == -1
                    props.far = Inf;
                else
                    props.far = obj(4,3) / ( obj(3,3) + 1 );
                end
                props.left = props.near * ( obj(3,1) - 1 ) / obj(1,1);
                props.right = props.near * ( obj(3,1) + 1 ) / obj(1,1);
                props.bottom = props.near * ( obj(3,2) - 1 ) / obj(2,2);
                props.top = props.near * ( obj(3,2) + 1 ) / obj(2,2);
                props.aspectRatio = obj(2,2) / obj(1,1);
                props.fovX = 2 * atan( ( obj(1,3) + 1 ) / obj(1,1) );
                props.fovY = 2 * atan( ( obj(3,2) + 1 ) / obj(2,2) );
            else % obj(4,4) == 1
                % Orthographic projection matrix.
                props.near = ( obj(4,3) + 1 ) / obj(3,3);
                props.far = ( obj(4,3) - 1 ) / obj(3,3);
                props.left = - ( obj(4,1) + 1 ) / obj(1,1);
                props.right = ( 1 - obj(4,1) ) / obj(1,1);
                props.bottom = - ( obj(4,2) + 1 ) / obj(2,2);
                props.top = ( 1 - obj(4,2) ) / obj(2,2);
                props.aspectRatio = obj(2,2) / obj(1,1);
                props.fovX = NaN;
                props.fovY = NaN;
            end
        end
    end
    methods(Static,Access=private)
        function validateprojection( data )
            id = "ProjectionMatrix:InvalidProjectionMatrix";
            if ~isequal( size( data ), [ 4 4 ] ) || ~isnumeric( data )
                msg = "A projection matrix must be a 4-by-4 " + ...
                    "numeric matrix.";
                throwAsCaller( MException( id, msg ) )
            elseif ~isreal( data ) || anynan( data ) || ...
                    ~allfinite( data )
                msg = "A projection matrix cannot contain NaN, " + ...
                    "Inf, or imaginary elements.";
                throwAsCaller( MException( id, msg ) )
            elseif ~isequal( data([2 4:5 8:10 13:16]), ...
                    [0 0 0 0 0 0 0 0 -1 0] ) && ...
                    ~isequal( data([2:5 7:8 12:14 16]), ...
                    [0 0 0 0 0 0 -1 0 0 0] ) && ...
                    ~isequal( data([2:3 5 7 9:10 13:16]), ...
                    [0 0 0 0 0 0 0 0 0 1] ) && ...
                    ~isequal( data([2:5 7:10 12 16]), ...
                    [0 0 0 0 0 0 0 0 0 1] )
                % Allow for incorrectly transposed projection matrices.
                msg = "The projection matrix does not conform " + ...
                    "to the expected format, i.e., the positions " + ...
                    "of 0s and 1 or -1.";
                throwAsCaller( MException( id, msg ) )
            end
        end
        function validatecameraprops( varargin )
            [ fovY, aspectRatio, near, far ] = varargin{:};
            id = "ProjectionMatrix:InvalidCameraProperties";
            msg = "The field-of-view and aspect ratio must both be ";
            if ~isscalar( fovY ) || ~isnumeric( fovY ) || ...
                    ~isscalar( aspectRatio ) || ~isnumeric( aspectRatio )
                msg = msg + "numeric scalars.";
                throwAsCaller( MException( id, msg ) )
            elseif anynan( [fovY aspectRatio] ) || ...
                    ~allfinite( [fovY aspectRatio] ) || ...
                    ~isreal( [fovY aspectRatio] )
                msg = msg + "non-nan, finite, and real.";
                throwAsCaller( MException( id, msg ) )
            elseif fovY <= 0 || aspectRatio <= 0
                msg = msg + "greater than 0.";
                throwAsCaller( MException( id, msg ) )
            end
            ProjectionMatrix.validatefrustum( -1, 1, -1, 1, near, far, ...
                "perspective" )
        end
        function validateintrinsics( varargin )
            [ intrinsics, imageSize, near, far ] = varargin{:};
            id = "ProjectionMatrix:InvalidIntrinsicMatrix";
            if ~isequal( size( intrinsics ), [ 3 3 ] ) || ...
                    ~isnumeric( intrinsics )
                msg = "An intrinsic matrix must be a 3-by-3 numeric " + ...
                    "matrix.";
                throwAsCaller( MException( id, msg ) )
            elseif ~isreal( intrinsics ) || anynan( intrinsics ) || ...
                    ~allfinite( intrinsics )
                msg = "An intrinsic matrix cannot contain NaN, " + ...
                    "Inf, or imaginary elements.";
                throwAsCaller( MException( id, msg ) )
            elseif ~isequal( intrinsics([2 3 6 9]), [0 0 0 1] ) && ...
                    ~isequal( intrinsics([4 7 8 9]), [0 0 0 1] )
                % Allow for incorrectly transposed intrinsic matrices.
                msg = "The intrinsic matrix does not conform " + ...
                    "to the expected format, i.e., the positions " + ...
                    "of 0s and 1.";
                throwAsCaller( MException( id, msg ) )
            end
            id = "ProjectionMatrix:InvalidImageSize";
            if numel( imageSize ) ~= 2 || ~isnumeric( imageSize ) || ...
                    ~all( imageSize > 0 ) || ...
                    ~all( imageSize == floor( imageSize ) )
                msg = "Image size must be a 2-element vector of " + ...
                    "positive integers, in the form [width height].";
                throwAsCaller( MException( id, msg ) )
            elseif anynan( imageSize ) || ~allfinite( imageSize ) || ...
                    ~isreal( imageSize )
                msg ="Image size must be non-nan, finite, and real.";
                throwAsCaller( MException( id, msg ) )
            end
            ProjectionMatrix.validatefrustum( -1, 1, -1, 1, near, far, ...
                "perspective" )
        end
        function validatefrustum( varargin )
            [ left, right, bottom, top, near, far, type ] = varargin{:};
            id = "ProjectionMatrix:InvalidFrustum";
            if ~all( cellfun( @(x) isscalar( x ) & isnumeric( x ), ...
                    varargin(1:6) ), "all" )
                msg = "The positions of the frustum planes must" + ...
                    " numeric scalars.";
                throwAsCaller( MException( id, msg ) )
            elseif any( cellfun( @(x) ~isreal( x ) | isnan( x ), ...
                    varargin(1:6) ), "all" ) || ...
                    any( cellfun( @isinf, varargin(1:5) ), "all" )
                msg = "The positions of the frustum planes must" + ...
                    " be non-nan, finite, and real, with the " + ...
                    "exception of the far plane which can be " + ...
                    "infinite for perspective projections.";
                throwAsCaller( MException( id, msg ) )
            elseif near <= 0 || far <= 0
                msg = "The position of near and far frustum " + ...
                    "planes must be positive.";
                throwAsCaller( MException( id, msg ) )
            elseif near >= far || bottom >= top || left >= right
                msg = "The position of near, top, and right " + ...
                    "frustum planes must greater than the far, " + ...
                    "bottom, and top planes, respectively.";
                throwAsCaller( MException( id, msg ) )
            end
            if ~(ischar(type) && isrow(type)) && ...
                    ~(isstring(type) && isscalar(type)) || ...
                    ~any( strncmpi( type, ...
                    [ "orthographic", "perspective" ], 1 ) )
                id = "ProjectionMatrix:InvalidProjectionType";
                msg = "The projection type must be a text scalar, " + ...
                    "with the value 'perspective' or 'orthographic'.";
                throwAsCaller( MException( id, msg ) )
            elseif isinf( far ) && strncmpi( type, "orthographic", 1 )
                msg = "The far-clipping plane cannot be at infinity " + ...
                    "for orthographic projections.";
                throwAsCaller( MException( id, msg ) )
            end
        end
    end
end