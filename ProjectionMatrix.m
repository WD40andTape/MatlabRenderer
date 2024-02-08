classdef ProjectionMatrix < double
%PROJECTIONMATRIX Build, store, and modify a camera projection matrix.
%
% VALUE
%   The value of a ProjectionMatrix object is a 4-by-4 projection matrix. 
%   It is row-major, right-handed, and the camera is aligned along the 
%   world coordinate system's negative Z-axis. Row-major order means that 
%   points are represented by row vectors and projected points are given by 
%   pre-multiplication, i.e., points * matrix.
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
%       Build a camera projection matrix.
% 
%       A projection matrix can be built either with the camera's 
%       field-of-view and aspect ratio, or by defining the frustum
%       coordinates directly.
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
    methods
        function obj = ProjectionMatrix( varargin )
            %PROJECTIONMATRIX Build a camera projection matrix.
            %
            % SYNTAX
            %   obj = ProjectionMatrix()
            %   obj = ProjectionMatrix(matrix)
            %   obj = ProjectionMatrix(fovY, aspectRatio, near)
            %   obj = ProjectionMatrix(fovY, aspectRatio, near, far)
            %   obj = ProjectionMatrix(left, right, bottom, top, near)
            %   obj = ProjectionMatrix(left, right, bottom, top, near, far)
            %
            % INPUTS
            %   matrix       4-by-4 projection matrix. matrix must be 
            %                 row-major and right-handed. A row-major 
            %                 projection matrix will have 0s in elements 
            %                 (1,3) and (2,3).  Convert between row- and 
            %                 column-major order by taking the transpose, 
            %                 i.e, matrix = matrix'. A right-handed 
            %                 row-major projection matrix will 
            %                 have a -1 in element (3,4). For row-major 
            %                 matrices, convert between handedness by 
            %                 negating the 3rd row, i.e., 
            %                 matrix(3,:) = -matrix(3,:).
            %   fovY         The field-of-view, in radians, in the Y 
            %                 (vertical) direction.
            %   aspectRatio  The aspect ratio, which establishes the 
            %                 field-of-view in the X direction. Given as 
            %                 the ratio of X to Y, i.e., 
            %                 image width / height.
            %   near         The distance from the optical center to the 
            %                 near-clipping plane, in world units, measured 
            %                 along the camera's line-of-sight (local 
            %                 Z-axis). Objects closer than near are not 
            %                 rendered. near must be positive and finite.
            %   far          The distance to the far-clipping plane, in 
            %                 world units. Objects further than far are not 
            %                 rendered. far must be positive and may be 
            %                 infinite. By default, far is infinite (Inf).
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
            %   default projection matrix is provided. The default 
            %   projection matrix has an aspect ratio of 1, a 90-degree 
            %   field-of-view, the near-clipping plane at 0.5, and the far 
            %   clipping-plane at infinity.
            %
            % OUTPUTS
            %   obj          For documentation, use the command:
            %                   doc ProjectionMatrix
            % 
            if nargin == 0
                % Use a default projection matrix.
                data = [1 0 0 0; 0 1 0 0; 0 0 -1 -1; 0 0 -1 0];
            elseif nargin == 1
                % Use the provided projection matrix.
                ProjectionMatrix.validatematrix( varargin{1} )
                if ~isequal( varargin{1}([3 7 12]), [0 0 -1] ) && ...
                        isequal( varargin{1}([9 10 15]), [0 0 -1] )
                    warning( "Detected column-major projection " + ...
                        "matrix, when it should have been " + ...
                        "row-major. Transpose the matrix to remove " + ...
                        "this warning." )
                    varargin{1} = varargin{1}';
                end
                data = varargin{1};
            elseif nargin == 3 || nargin == 4
                % Build projection matrix from the field-of-view in the 
                % Y direction, the aspect ratio of the image, and the Z 
                % position of the near and optionally far frustum planes.
                if nargin == 3
                    varargin{4} = Inf;
                end
                ProjectionMatrix.validatecameraprops( varargin{:} )
                [ fovY, aspectRatio, near, far ] = varargin{:};
                data = zeros( 4 );
                data(1,1) = 1 / (aspectRatio * tan( fovY / 2 ));
                data(2,2) = 1 / tan( fovY / 2 );
                data(3,4) = -1;
                if isinf( far )
                    data(3,3) = -1;
                    data(4,3) = -2 * near;
                else
                    data(3,3) = -(far + near) / (far - near);
                    data(4,3) = -(2 * far * near) / (far - near);
                end
            elseif nargin == 5 || nargin == 6
                % Build projection matrix from the position of the 
                % frustum's planes.
                if nargin == 5
                    varargin{6} = Inf;
                end
                ProjectionMatrix.validatefrustum( varargin{:} )
                [ left, right, bottom, top, near, far ] = varargin{:};
                % 
                data = zeros( 4 );
                data(1,1) = 2 * near / (right - left);
                data(2,2) = 2 * near / (top - bottom);
                data(3,1) = (right + left) / (right - left);
                data(3,2) = (top + bottom) / (top - bottom);
                data(3,4) = -1;
                if isinf( far )
                    % Alternatively, see slide 15 of: https://www.terathon.com/gdc07_lengyel.pdf
                    data(3,3) = -1;
                    data(4,3) = -2 * near;
                else
                    data(3,3) = -(far + near) / (far - near);
                    data(4,3) = -(2 * far * near) / (far - near);
                end
            else
                id = "ProjectionMatrix:WrongNumberOfInputs";
                msg = "ProjectionMatrix was called with the wrong " + ...
                    "number of inputs. Please check the class syntax.";
                throwAsCaller( MException( id, msg ) )
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
            %               fovY         The field-of-view, in radians, 
            %                             in the Y (vertical) direction.
            %               fovX         The field-of-view, in radians, in 
            %                             the X (horizontal) direction.
            %               aspectRatio  The aspect ratio of the 
            %                             field-of-view. Given as the ratio 
            %                             of X to Y, i.e., 
            %                             image width / height.
            %
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
            props.fovY = 2 * atan( ( obj(3,2) + 1 ) / obj(2,2) );
            props.fovX = 2 * atan( ( obj(1,3) + 1 ) / obj(1,1) );
            props.aspectRatio = obj(2,2) / obj(1,1);
        end
    end
    methods(Static,Access=private)
        function validatematrix( data )
            id = "ProjectionMatrix:InvalidMatrix";
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
                    [0 0 0 0 0 0 -1 0 0 0] )
                % Allow for incorrectly transposed projection matrices.
                msg = "The projection matrix does not conform " + ...
                    "to the expected format, i.e., the positions " + ...
                    "of 0s and -1.";
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
            ProjectionMatrix.validatefrustum( -1, 1, -1, 1, near, far )
        end
        function validatefrustum( varargin )
            [ left, right, bottom, top, near, far ] = varargin{:};
            id = "ProjectionMatrix:InvalidFrustum";
            if ~all( cellfun( @(x) isscalar( x ) & isnumeric( x ), ...
                    varargin ), 'all' )
                msg = "The positions of the frustum planes must" + ...
                    " numeric scalars.";
                throwAsCaller( MException( id, msg ) )
            elseif any( cellfun( @(x) ~isreal( x ) | isnan( x ), ...
                    varargin ), 'all' ) || ...
                    any( cellfun( @isinf, varargin(1:5) ), 'all' )
                msg = "The positions of the frustum planes must" + ...
                    " be non-nan, finite, and real, with the " + ...
                    "exception of the far plane which can be infinite.";
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
        end
    end
end