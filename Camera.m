classdef Camera < handle
    %CAMERA Object for plotting a camera and storing its properties.
    %
    % PROPERTIES
    %   projectionMatrix  4-by-4 projection matrix. For detailed 
    %                     documentation, use the command:
    %                        doc Camera.projectionMatrix
    %   imageSize         Camera resolution, [width height]. For detailed 
    %                     documentation, use the command:
    %                        doc Camera.imageSize
    %   t                 Camera translation, [x y z]. For detailed 
    %                     documentation, use the command:
    %                        doc Camera.t
    %   R                 3-by-3 camera rotation matrix. For detailed 
    %                     documentation, use the command:
    %                        doc Camera.R
    %   plotHandles       Graphics handles. For detailed documentation, 
    %                     use the command:
    %                        doc Camera.plotHandles
    %
    % METHODS
    %   Constructor
    %       Set and validate Camera properties.
    %       For detailed documentation, use the command:
    %           doc Camera.Camera
    %   plotcamera
    %       Plot a mesh representing the camera.
    %       For detailed documentation, use the command:
    %           doc Camera.plotcamera
    %   plotframe
    %       Plot the camera's Cartesian coordinate system.
    %       For detailed documentation, use the command:
    %           doc Camera.plotframe
    %   plotfov
    %       Plot a mesh representing the camera's field-of-view.
    %       For detailed documentation, use the command:
    %           doc Camera.plotfov
    %   setview
    %       Set the MATLAB axes's view to match the Camera object.
    %       For detailed documentation, use the command:
    %           doc Camera.setview
    %
    properties (Access = public)
        % projectionMatrix - Used for rendering
        %
        % 4-by-4 projection matrix. It is row-major, right-handed, and the 
        % camera is aligned along the world coordinate system's negative 
        % Z-axis. Row-major order means that points are represented by row 
        % vectors and projected points are given by pre-multiplication, 
        % i.e., points * matrix.
        %
        projectionMatrix (4,4) { mustBeFloat }
        
        % imageSize - Camera resolution
        %
        % 2-element integer vector, in the form [width height]. Its default 
        % value is [100 100].
        %
        imageSize (1,2) { mustBeInteger, mustBePositive } = [100 100]
        
        % t - Translation
        %
        % 3-element numeric vector specifying the camera's translation 
        % (position), in the form [X Y Z]. Its default value is [0 0 0].
        %
        t (1,3) { mustBeNumeric, mustBeNonNan } = [0 0 0]
        
        % R - Rotation matrix
        %
        % 3-by-3 rotation matrix specifying the camera's 3D rotation 
        % (orientation). It is right-handed and row-major. Row-major order 
        % means that the rows of R denote its basis vectors, i.e., 
        % [X1 Y1 Z1; X2 Y2 Z2; X3 Y3 Z3]. Its default value is 
        % [1 0 0; 0 -1 0; 0 0 -1].
        %
        R (3,3) { Camera.mustBeRightHanded } = [1 0 0; 0 -1 0; 0 0 -1]
        
        % plotHandles - Graphics handles
        %
        % Structure array containing the fields:
        %  - frame   If plotframe has not been called, the frame field is 
        %            empty. Else, it contains a 1-by-6 graphics object 
        %            array holding 3 Quiver objects and 3 Text objects, in 
        %            the form [quiverX quiverY quiverZ textX textY textZ].
        %  - fov     If plotfov has not been called, the fov field is 
        %            empty. Else, it contains a Patch object.
        %  - camera  If plotcamera has not been called, the camera field is 
        %            empty. Else, it contains a Patch object.
        %
        plotHandles (1,1) struct { mustHaveFields( plotHandles, ...
            [ "frame", "fov", "camera" ] ) } = struct( ...
            "frame", gobjects, "fov", gobjects, "camera", gobjects )
    end
    methods
        function obj = Camera( projectionMatrix, imageSize, t, R )
            %CAMERA Set and validate Camera properties.
            %
            % SYNTAX
            %   obj = Camera( projectionMatrix )
            %   obj = Camera( projectionMatrix, imageSize )
            %   obj = Camera( projectionMatrix, imageSize, t )
            %   obj = Camera( projectionMatrix, imageSize, t, R )
            %
            % INPUTS
            %   projectionMatrix  4-by-4 projection matrix. For detailed 
            %                     documentation, use the command:
            %                        doc Camera.projectionMatrix
            %   imageSize         Camera resolution, [width height]. For  
            %                     detailed documentation, use the command:
            %                        doc Camera.imageSize
            %   t                 Camera translation, [x y z]. For detailed 
            %                     documentation, use the command:
            %                        doc Camera.t
            %   R                 3-by-3 camera rotation matrix. For 
            %                     detailed documentation, use the command:
            %                        doc Camera.R
            %
            % OUTPUTS
            %   obj               For documentation, use the command:
            %                        doc Camera
            %
            obj.projectionMatrix = projectionMatrix;
            if nargin > 1 && ~isempty( imageSize )
                obj.imageSize = imageSize;
                projAspectRatio = ...
                    obj.projectionMatrix(2,2) / obj.projectionMatrix(1,1);
                imageAspectRatio = obj.imageSize(1) / obj.imageSize(2);
                if abs( projAspectRatio - imageAspectRatio ) > 1e-4
                    warning( "The aspect ratio of projectionMatrix " + ...
                        "and imageSize are not equal. The camera " + ...
                        "image will appear stretched." )
                end
            end
            if nargin > 2 && ~isempty( t )
                obj.t = t;
            end
            if nargin > 3 && ~isempty( R )
                obj.R = R;
            end
        end
        
        function delete( obj )
            %DELETE Delete graphics objects on object destruction.
            fields = fieldnames( obj.plotHandles );
            for i = 1 : numel( fields )
                delete( obj.plotHandles.(fields{i}) )
            end
        end
        
        function set.projectionMatrix( obj, projectionMatrix )
            % Update the field-of-view plot, if one exists, when the 
            % camera's projection matrix changes, e.g., it zooms in.
            obj.projectionMatrix = projectionMatrix;
            obj.updateplots()
        end
        function set.imageSize( obj, imageSize )
            % Update the field-of-view plot, if one exists, when the 
            % camera's image resolution changes.
            obj.imageSize = imageSize;
            obj.updateplots()
        end
        function set.t( obj, t )
            % Update the camera, coordinate frame, and field-of-view plots
            % when the camera translates.
            obj.t = t;
            obj.updateplots()
        end
        function set.R( obj, R )
            % Update the camera, coordinate frame, and field-of-view plots
            % when the camera rotates.
            obj.R = R;
            obj.updateplots()
        end
        
        function h = plotframe( obj, ax, len )
            %PLOTFRAME Plot the camera's Cartesian coordinate system.
            %
            % SYNTAX
            %   h = obj.plotframe( ax, len )
            %
            % INPUTS
            %   ax    Axes in which to plot. Must be a scalar axes, group 
            %         (hggroup), or transform (hgtransform) object. The 
            %         default is the current axes (gca).
            %   len   Length to plot each arrow (basis) of the coordinate 
            %         frame. Numeric scalar. The default is 1.
            %
            % OUTPUTS
            %   h     1-by-6 graphics object array containing 3 Quiver 
            %         objects and 3 Text objects, in the form 
            %         [quiverX quiverY quiverZ textX textY textZ]. h is 
            %         also stored in obj.plotHandles.frame .
            %
            arguments
                obj
                ax (1,1) { Camera.mustBeParent( ax ) } = gca
                len (1,1) { mustBePositive } = 1
            end
            %
            if any( ~isgraphics( obj.plotHandles.frame ) )
                if isfield( obj.plotHandles, "frame" )
                    delete( obj.plotHandles.frame )
                end
                % Match the behaviour of patch, used by the other plotting 
                % functions, in not clearing the axes.
                holdState = get( ax, "NextPlot" );
                set( ax, "NextPlot", "add" )
                h(1) = quiver3( [], [], [], [], [], [], "Parent", ax, ...
                    "Color", "r" );
                h(2) = quiver3( [], [], [], [], [], [], "Parent", ax, ...
                    "Color", "g" );
                h(3) = quiver3( [], [], [], [], [], [], "Parent", ax, ...
                    "Color", "b" );
                set( h, "AutoScale", "off", ...
                    "LineWidth", 2, "MaxHeadSize", 0.4 )
                h(4) = text( ax, 0, 0, 0, "" );
                h(5) = text( ax, 0, 0, 0, "" );
                h(6) = text( ax, 0, 0, 0, "" );
                set( ax, "NextPlot", holdState ); % Restore the state.
                obj.plotHandles.frame = h;
            end
            xAxis = obj.R(1,:) .* len;
            yAxis = obj.R(2,:) .* len;
            zAxis = obj.R(3,:) .* len;
            % Update positions and labels
            h = obj.plotHandles.frame;
            set( h(1:3), "XData", obj.t(1), "YData", obj.t(2), ...
                "ZData", obj.t(3) )
            set( h(1), "UData", xAxis(1), "VData", xAxis(2), ...
                "WData", xAxis(3) )
            set( h(2), "UData", yAxis(1), "VData", yAxis(2), ...
                "WData", yAxis(3) )
            set( h(3), "UData", zAxis(1), "VData", zAxis(2), ...
                "WData", zAxis(3) )
            set( h(4), "Position", obj.t + xAxis, "String", "X" )
            set( h(5), "Position", obj.t + yAxis, "String", "Y" )
            set( h(6), "Position", obj.t + zAxis, "String", "Z" )
        end
        
        function h = plotcamera( obj, ax, len )
            %PLOTCAMERA Plot a mesh representing the camera.
            %
            % SYNTAX
            %   h = obj.plotcamera( ax, len )
            %
            % INPUTS
            %   ax    Axes in which to plot. Must be a scalar axes, group 
            %         (hggroup), or transform (hgtransform) object. The 
            %         default is the current axes (gca).
            %   len   Length to plot the camera, between the its back and
            %         lens. Numeric scalar. The default is 1.
            %
            % OUTPUTS
            %   h     Patch object. h is also stored in 
            %         obj.plotHandles.camera .
            %
            arguments
                obj
                ax (1,1) { Camera.mustBeParent( ax ) } = gca
                len (1,1) { mustBePositive } = 1
            end
            % Credit to MATLAB's built-in plotcamera for the geometry of 
            % the mesh representing the camera.
            l = 2/3 * len; % Length of the camera body.
            w = 1/3 * len; % Width of the camera body.
            wo = w / 2; % Width offset between the camera's rim and body.
            lo = l + w; % Length offset between the camera's rim and body.
            % The first 4 vertices are for the back of the camera, the next 
            % 4 are for the front, and the last 4 are for the rim and lens.
            vertices = [ 0 0 lo; 0 w lo; w w lo; w 0 lo; ...
                         0 0 w; 0 w w; w 0 w; w w w; ...
                         -wo -wo 0; w+wo -wo 0; w+wo w+wo 0; -wo w+wo 0 ];
            % Shift the vertices to center the camera on the origin.
            vertices = vertices - [ w / 2, w / 2, w * 2 ];
            if ~isgraphics( obj.plotHandles.camera )
                % Row 1 defines the back of the camera.
                % Rows 2-5 define the sides of the camera.
                % Rows 6-9 define the rim of the camera.
                % Row 10 defines the lens of the camera.
                faces = [1 2 3 4; ...
                     1 5 6 2; 1 5 7 4; 4 7 8 3; 3 8 6 2; ...
                     5 9 10 7; 7 10 11 8; 8 11 12 6; 6 12 9 5; ...
                     9 10 11 12];
                % C sets the camera to black and the lens to yellow.
                C = [ zeros( size( faces, 1 ) - 1, 3 ); 1 1 0 ];
                h = patch( ax, "Faces", faces, "Vertices", vertices, ...
                    "FaceVertexCData", C, "FaceColor", "flat", ...
                    "FaceLighting", "none" );
                h.UserData = len; % Used in updateplots().
                obj.plotHandles.camera = h;
            end
            % Rotate the vertices to position the camera's pose.
            obj.plotHandles.camera.Vertices = vertices * obj.R + obj.t;
        end
        
        function h = plotfov( obj, ax, dist )
            %PLOTFOV Plot a mesh representing the camera's field-of-view.
            %
            % SYNTAX
            %   h = obj.plotfov( ax, dist )
            %
            % INPUTS
            %   ax    Axes in which to plot. Must be a scalar axes, group 
            %         (hggroup), or transform (hgtransform) object. The 
            %         default is the current axes (gca).
            %   dist  Distance to plot the camera's field-of-view from the 
            %         camera's optical center. Numeric scalar. The default 
            %         is 1.
            %
            % OUTPUTS
            %   h     Patch object. h is also stored in 
            %         obj.plotHandles.fov .
            %
            % Note that plotfov depends on the function, raycast, which is
            % stored in a seperate MATLAB file.
            %
            arguments
                obj
                ax (1,1) { Camera.mustBeParent( ax ) } = gca
                dist (1,1) { mustBePositive } = 1
            end
            if exist( 'raycast', 'file' ) ~= 2
                warning( "plotfov depends on the raycast function, " + ...
                    "which was not found on the search path." )
                return
            end
            % Project points from the corners of the image to find the 
            % edges of the field-of-view.
            cornerPixels = [ 1 1; obj.imageSize(1) 1; ...
                           obj.imageSize; 1 obj.imageSize(2) ];
            edgeRaysNearPlane = raycast( obj, cornerPixels );
            nearPlaneDist = obj.projectionMatrix(4,3) / ...
                ( obj.projectionMatrix(3,3) - 1 );
            edgeRaysFarPlane = edgeRaysNearPlane * dist / nearPlaneDist;
            vertices = [ obj.t; obj.t + edgeRaysFarPlane ];
            if ~isgraphics( obj.plotHandles.fov )
                faces = [ 1 2 3; 1 3 4; 1 4 5; 1 5 2 ];
                h = patch( ax, "Faces", faces, "Vertices", ...
                    vertices, "FaceColor", [0 0 0], "FaceAlpha", 0.1 );
                h.UserData = dist; % Used in updateplots().
                obj.plotHandles.fov = h;
            else
                obj.plotHandles.fov.Vertices = vertices;
            end
        end
        
        function setview( obj, ax )
            %SETVIEW Set the MATLAB axes's view to match the Camera object.
            %
            % SYNTAX
            %   obj.setview( ax )
            %
            % INPUTS
            %   ax    Target axes. Axes object or array of Axes objects. 
            %         The default is the current axes (gca).
            %
            % Be aware that changing the low-level CameraViewAngle property 
            % to match the Camera object's field-of-view changes the 
            % position of the axes within the figure. The axes used for 
            % this purpose should therefore be in a standalone figure, or 
            % its position should be set manually.
            %
            % Also note that MATLAB's camera will produce a similar but not 
            % identical image to the one rendered using a projection 
            % matrix. In particular, MATLAB's camera does not apply limits 
            % to the render in image space according to image resolution. 
            % This is instead controlled by the axes limits in world space. 
            % MATLAB will therefore render objects outside of the camera's 
            % field-of-view. Furthermore, MATLAB's camera does explicitly 
            % have a near-clipping plane, objects closer than which are not 
            % rendered with a projection matrix.
            %
            arguments
                obj
                ax { Camera.mustBeAxes }
            end
            fovY = 2 * atand( ( obj.projectionMatrix(3,2) + 1 ) / ...
                obj.projectionMatrix(2,2) );
            set( ax, "DataAspectRatio", [1 1 1], ...
                     "Projection", "perspective", ...
                     "CameraViewAngle", fovY, ...
                     "CameraPosition", obj.t, ...
                     "CameraTarget", obj.t - obj.R(3,:), ...
                     "CameraUpVector", obj.R(2,:) )
        end
    end

    methods(Access=private)
        function updateplots( obj )
            %UPDATEPLOTS Update the camera, frame, and field-of-view plots, 
            % if they exist, when the Camera properties change, e.g., if 
            % the camera moves.
            if all( isgraphics( obj.plotHandles.frame ) )
                h = obj.plotHandles.frame;
                length = norm( [ h(1).UData, h(1).VData, h(1).WData ] );
                plotframe( obj, h(1).Parent, length );
            end
            if isgraphics( obj.plotHandles.fov )
                plotfov( obj, obj.plotHandles.fov.Parent, ...
                    obj.plotHandles.fov.UserData );
            end
            if isgraphics( obj.plotHandles.camera )
                plotcamera( obj, obj.plotHandles.frame(1).Parent, ...
                    obj.plotHandles.camera.UserData );
            end
        end
    end

    methods(Static,Access=private)
        function mustBeRightHanded( matrix, tolerance )
            %MUSTBERIGHTHANDED Throw error if matrix is not right-handed.
            %
            % SYNTAX
            %   Camera.mustBeRightHanded( matrix, tolerance )
            %
            % INPUTS
            %   matrix     3-by-3 rotation matrix.
            %   tolerance  Positive numeric scalar used to determine 
            %              whether the matrix is sufficiently close to 
            %              right-handed. By default, 1e-4.
            %
            arguments
                matrix (3,3) { mustBeFloat, mustBeNonNan, mustBeReal }
                tolerance (1,1) { mustBeNumeric, mustBeNonNan } = 1e-4
            end
            if any( abs( matrix * matrix' - eye( 3 ) ) >= tolerance )
                % Matrix is orthonormal (orthogonal) if multiplication of 
                % itself with its transpose gives the identity matrix.
                id = "Camera:Validators:MatrixNotOrthonormal";
                msg = sprintf( "Must be orthonormal within " + ...
                    "tolerance %s. Either the basis vectors (rows) " + ...
                    "are not perpendicular or they do not have a " + ...
                    "Euclidean length equal to 1.", string( tolerance ) );
                throw( MException( id, msg ) )
            elseif abs( det( matrix ) - 1 ) >= tolerance
                % Right-handed rotation matrices have a determinant of 1.
                id = "Camera:Validators:MatrixNotRightHanded";
                msg = sprintf( "Must be a valid rotation matrix and " + ...
                    "right-handed within tolerance %s.\nChange the " + ...
                    "handedness by:\n -\tPermuting 2 rows (basis " + ...
                    "vectors).\n -\tNegating 1 or 3 rows.\n -\t" + ...
                    "Performing a reflection through a plane.", ...
                    string( tolerance ) );
                throw( MException( id, msg ) )
            end
        end
        function mustBeParent( x )
            %MUSTBEPARENT Throw error if x isn't a graphics objects parent.
            % ax must be an axes, group (hggroup), or transform 
            % (hgtransform) object, and must not have been deleted (closed, 
            % cleared, etc).
            %
            % SYNTAX
            %   Camera.mustBeParent( x )
            %
            % INPUTS
            %   x   Scalar of any type. No error is thrown if all elements 
            %       of x are valid graphics parent objects.
            %
            isParent = isgraphics( x, "matlab.graphics.axis.Axes" ) || ...
                isgraphics( x, "matlab.graphics.primitive.Group" ) || ...
                isgraphics( x, "matlab.graphics.primitive.Transform" );
            if ~isParent
                id = "Camera:Validators:InvalidParent";
                msg = "Must be handle to a graphics object " + ...
                    "parent which has not been deleted.";
                throwAsCaller( MException( id, msg ) )
            end
        end
        function mustBeAxes( ax )
            %MUSTBEAXES Throw error if ax aren't valid Axes objects.
            %
            % SYNTAX
            %   Camera.mustBeAxes( ax )
            %
            % INPUTS
            %   ax   Input of any type. No error is thrown if all elements 
            %        of ax are valid Axes objects.
            %
            if ~all( isgraphics( ax, "matlab.graphics.axis.Axes" ) )
                id = "Camera:Validators:InvalidAxes";
                msg = "Must be handle to one or more Axes objects " + ...
                    "which have not been deleted.";
                throwAsCaller( MException( id, msg ) )
            end
        end
    end
end