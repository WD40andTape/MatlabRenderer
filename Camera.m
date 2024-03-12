classdef Camera < handle
%CAMERA Object for plotting a camera and storing its properties.
%
% PROPERTIES
%   projectionMatrix  4-by-4 projection matrix. For detailed documentation, 
%                      use the command:
%                        <a href="matlab: doc Camera.projectionMatrix"
%                           >doc Camera.projectionMatrix</a>
%   imageSize         Camera resolution, [width height]. For detailed 
%                      documentation, use the command:
%                        <a href="matlab: doc Camera.imageSize"
%                           >doc Camera.imageSize</a>
%   t                 Camera translation, [x y z]. For detailed 
%                      documentation, use the command:
%                        <a href="matlab: doc Camera.t"
%                           >doc Camera.t</a>
%   R                 3-by-3 camera rotation matrix. For detailed 
%                      documentation, use the command:
%                        <a href="matlab: doc Camera.R"
%                           >doc Camera.R</a>
%   plotHandles       Graphics handles. For detailed documentation, use the 
%                      command:
%                        <a href="matlab: doc Camera.plotHandles"
%                           >doc Camera.plotHandles</a>
%
% METHODS
%   Constructor
%       Set and validate Camera properties.
%       For detailed documentation, use the command:
%           <a href="matlab: doc Camera.Camera"
%               >doc Camera.Camera</a>
%   plotcamera
%       Plot a mesh representing the camera.
%       For detailed documentation, use the command:
%           <a href="matlab: doc Camera.plotcamera"
%               >doc Camera.plotcamera</a>
%   plotframe
%       Plot the camera's Cartesian coordinate system.
%       For detailed documentation, use the command:
%           <a href="matlab: doc Camera.plotframe"
%               >doc Camera.plotframe</a>
%   plotfov
%       Plot a mesh representing the camera's field-of-view.
%       For detailed documentation, use the command:
%           <a href="matlab: doc Camera.plotfov"
%               >doc Camera.plotfov</a>
%   setview
%       Set the MATLAB axes's view to match the Camera object.
%       For detailed documentation, use the command:
%           <a href="matlab: doc Camera.setview"
%               >doc Camera.setview</a>
%
% EXAMPLE: Please see the file 'example.m'.
% 
% Please note that Camera depends on the functions, mustHaveFields and 
% raycast, which are stored in seperate MATLAB files. Created in 2022b. 
% Compatible with 2021a and later. Compatible with all platforms. Please 
% cite George Abrahams: https://github.com/WD40andTape/MatlabRenderer.

% Published under MIT License (see LICENSE.txt).
% Copyright (c) 2024 George Abrahams.
%  - https://github.com/WD40andTape/
%  - https://www.linkedin.com/in/georgeabrahams/
%  - https://scholar.google.com/citations?user=T_xxZLwAAAAJ

    properties(Access=public)
        % projectionMatrix - Used for rendering
        %
        % 4-by-4 perspective or orthographic projection matrix. It is 
        % row-major, right-handed, and the camera is aligned along the 
        % world coordinate system's negative Z-axis. Row-major order means 
        % that points are represented by row vectors and projected points 
        % are given by pre-multiplication, i.e., points * matrix. The near 
        % and far clip planes correspond to Z normalized device coordinates 
        % of -1 and +1 respectively.
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
        % (position), in world units, in the form [X Y Z]. Its default 
        % value is [0 0 0].
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
        %   camera  An Nx1 column vector of Patch objects, where N is the 
        %            number of valid camera graphics objects. If plotcamera 
        %            has not been called, or if all of the graphics objects 
        %            have been deleted, then N is 0.
        %   frame   An Nx6 graphics object array, where N is the number of
        %            valid frame graphics. If plotframe has not been 
        %            called, or if all of the graphics objects have been 
        %            deleted, then N is 0. Each row of the array references
        %            a single frame and contains 3 Quiver objects and 3 
        %            Text objects, in the form 
        %            [quiverX quiverY quiverZ textX textY textZ].
        %   fov     An Nx1 column vector of Patch objects, where N is the 
        %            number of valid field-of-view graphics objects. If 
        %            plotfov has not been called, or if all of the graphics 
        %            objects have been deleted, then N is 0.
        %
        % See also Camera.plotcamera, Camera.plotframe, Camera.plotfov.
        %
        plotHandles (1,1) struct { mustHaveFields( plotHandles, ...
            [ "camera", "frame", "fov" ] ) } = struct( "camera", ...
            gobjects(0,1), "frame", gobjects(0,6), "fov", gobjects(0,1) )
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
            %                      documentation, use the command:
            %                        <a href="matlab: doc Camera.projectionMatrix"
            %                           >doc Camera.projectionMatrix</a>
            %   imageSize         Camera resolution, [width height]. For  
            %                      detailed documentation, use the command:
            %                        <a href="matlab: doc Camera.imageSize"
            %                           >doc Camera.imageSize</a>
            %   t                 Camera translation, [x y z]. For detailed 
            %                      documentation, use the command:
            %                        <a href="matlab: doc Camera.t"
            %                           >doc Camera.t</a>
            %   R                 3-by-3 camera rotation matrix. For 
            %                      detailed documentation, use the command:
            %                        <a href="matlab: doc Camera.R"
            %                           >doc Camera.R</a>
            %
            % OUTPUTS
            %   obj               For documentation, use the command:
            %                        <a href="matlab: doc Camera"
            %                           >doc Camera</a>
            %
            obj.projectionMatrix = projectionMatrix;
            if nargin > 1 && ~isempty( imageSize )
                obj.imageSize = imageSize;
                projAspectRatio = ...
                    obj.projectionMatrix(2,2) / obj.projectionMatrix(1,1);
                imageAspectRatio = obj.imageSize(1) / obj.imageSize(2);
                if abs( projAspectRatio - imageAspectRatio ) > 0.05
                    warning( "The aspect ratio of projectionMatrix " + ...
                        "and imageSize may not be equal. The camera " + ...
                        "image could appear stretched." )
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
            %
            fields = fieldnames( obj.plotHandles );
            for i = 1 : numel( fields )
                delete( obj.plotHandles.(fields{i}) )
            end
        end
        
        function set.projectionMatrix( obj, projectionMatrix )
            % Update the field-of-view plot, if one exists, when the 
            % camera's projection matrix changes, e.g., it zooms in.
            %
            obj.projectionMatrix = projectionMatrix;
            obj.updateplots()
        end
        function set.imageSize( obj, imageSize )
            % Update the field-of-view plot, if one exists, when the 
            % camera's image resolution changes.
            %
            obj.imageSize = imageSize;
            obj.updateplots()
        end
        function set.t( obj, t )
            % Update the camera, coordinate frame, and field-of-view plots
            % when the camera translates.
            %
            obj.t = t;
            obj.updateplots()
        end
        function set.R( obj, R )
            % Update the camera, coordinate frame, and field-of-view plots
            % when the camera rotates.
            %
            obj.R = R;
            obj.updateplots()
        end
        
        function varargout = plotcamera( obj, ax, len )
            %PLOTCAMERA Plot a mesh representing the camera.
            % The camera plot will auto-update when the camera properties 
            % are changed, for example, if the camera moves. Multiple 
            % camera graphics may exist for a single Camera instance.
            %
            % SYNTAX
            %   h = obj.plotcamera( ax )
            %   h = obj.plotcamera( ax, len )
            %
            % INPUTS
            %   ax    Axes in which to plot. Must be a scalar axes, group 
            %          (hggroup), or transform (hgtransform) object. The 
            %          default is the current axes (gca).
            %   len   Length to plot the camera, between the its back and
            %          lens. Numeric scalar. The default is 1.
            %
            % OUTPUTS
            %   h     Patch object. h is also stored in 
            %          obj.plotHandles.camera .
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
            h = patch( ax, Faces=faces, Vertices=[], ...
                FaceVertexCData=C, FaceColor="flat", FaceLighting="none" );
            h.UserData = vertices; % Used in obj.updatecamera .
            obj.updatecamera( h )
            obj.plotHandles.camera = [ obj.plotHandles.camera; h ];
            if nargout > 0
                varargout{1} = h;
            end
        end
        
        function varargout = plotframe( obj, ax, lengths, labels )
            %PLOTFRAME Plot the camera's Cartesian coordinate system.
            % The frame plot will auto-update when the camera properties 
            % are changed, for example, if the camera moves. Multiple frame 
            % graphics may exist for a single Camera instance.
            %
            % For a more advanced, generalised version of plotframe, see:
            %  - https://mathworks.com/matlabcentral/fileexchange/156419-plotframe-plot-a-3-d-cartesian-coordinate-system
            %  - https://github.com/WD40andTape/plotframe/
            %
            % SYNTAX
            %   h = obj.plotframe( ax )
            %   h = obj.plotframe( ax, lengths )
            %   h = obj.plotframe( ax, lengths, labels )
            %
            % INPUTS
            %   ax       Axes in which to plot. Must be a scalar axes,  
            %             group (hggroup), or transform (hgtransform) 
            %             object. The default is the current axes (gca).
            %   lengths  Length to plot each arrow (basis) of the 
            %             coordinate frame. Scalar, 1-by-3, or 3-by-1 
            %             numeric vector. The default is 1.
            %   labels   Text with which to label each basis. Scalar, 
            %             1-by-3, or 3-by-1 text vector. Set to "" to 
            %             disable labels. The default is {'X';'Y';'Z'}.
            %
            % OUTPUTS
            %   h        1-by-6 graphics object array containing 3 Quiver 
            %             objects and 3 Text objects, in the form 
            %             [quiverX quiverY quiverZ textX textY textZ]. h is 
            %             also stored in obj.plotHandles.frame .
            %
            arguments
                obj
                ax (1,1) { Camera.mustBeParent( ax ) } = gca
                lengths (3,1) { mustBeNonnegative } = 1
                labels (3,1) { mustBeText } = { 'X'; 'Y'; 'Z' }
            end
            h(1) = matlab.graphics.chart.primitive.Quiver( Parent=ax );
            h(2) = matlab.graphics.chart.primitive.Quiver( Parent=ax );
            h(3) = matlab.graphics.chart.primitive.Quiver( Parent=ax );
            h(4) = matlab.graphics.primitive.Text( Parent=ax );
            h(5) = matlab.graphics.primitive.Text( Parent=ax );
            h(6) = matlab.graphics.primitive.Text( Parent=ax );
            set( h(1:3), ...
                "AutoScale", "off", "LineWidth", 2, "MaxHeadSize", 0.4, ...
                "UserData", lengths ) % UserData is used in obj.updateframe
            set( h(4:6), { 'String' }, cellstr( labels ) )
            obj.updateframe( h )
            obj.plotHandles.frame = [ obj.plotHandles.frame; h ];
            if nargout > 0
                varargout{1} = h;
            end
        end
        
        function varargout = plotfov( obj, ax, dist )
            %PLOTFOV Plot a mesh representing the camera's field-of-view.
            % The field-of-view plot will auto-update when the camera 
            % properties are changed, for example, if the camera moves. 
            % Multiple field-of-view graphics may exist for a single Camera 
            % instance.
            %
            % SYNTAX
            %   h = obj.plotfov( ax )
            %   h = obj.plotfov( ax, dist )
            %
            % INPUTS
            %   ax    Axes in which to plot. Must be a scalar axes, group 
            %          (hggroup), or transform (hgtransform) object. The 
            %          default is the current axes (gca).
            %   dist  Distance to plot the camera's field-of-view from the 
            %          camera's optical center. Numeric scalar. The default 
            %          is 1.
            %
            % OUTPUTS
            %   h     Patch object. h is also stored in 
            %          obj.plotHandles.fov .
            %
            % Please note that plotfov depends on the function, raycast, 
            % which is stored in a seperate MATLAB file.
            %
            arguments
                obj
                ax (1,1) { Camera.mustBeParent( ax ) } = gca
                dist (1,1) { mustBePositive } = 1
            end
            if exist( "raycast", "file" ) ~= 2
                warning( "plotfov depends on the raycast function, " + ...
                    "which was not found on the search path." )
                return
            end
            if obj.projectionMatrix(4,4) == 0
                % Perspective projection matrix.
                faces = [ 1 2 3; 1 3 4; 1 4 5; 1 5 2 ];
            else % obj.projectionMatrix(4,4) == 1
                % Orthographic projection matrix.
                faces = [ 1 2 3 4; 1 5 8 4; 1 5 6 2; 2 6 7 3; 3 7 8 4 ];
            end
            h = patch( ax, Faces=faces, Vertices=[], ...
                FaceColor=[0 0 0], FaceAlpha=0.1, FaceLighting="none" );
            h.UserData = dist; % Used in obj.updatefov .
            obj.updatefov( h )
            obj.plotHandles.fov = [ obj.plotHandles.fov; h ];
            if nargout > 0
                varargout{1} = h;
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
            %          The default is the current axes (gca).
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
            % field-of-view. Furthermore, MATLAB's camera does not 
            % explicitly have a near-clipping plane, objects closer than 
            % which are not rendered with a projection matrix.
            %
            arguments
                obj
                ax { Camera.mustBeAxes }
            end
            if obj.projectionMatrix(4,4) == 0
                % Perspective projection matrix. 
                fovY = 2 * atand( ( obj.projectionMatrix(3,2) + 1 ) / ...
                    obj.projectionMatrix(2,2) );
                set( ax, "DataAspectRatio", [1 1 1], ...
                         "Projection", "perspective", ...
                         "CameraViewAngle", fovY, ...
                         "CameraPosition", obj.t, ...
                         "CameraTarget", obj.t - obj.R(3,:), ...
                         "CameraUpVector", obj.R(2,:) )
            else % obj.projectionMatrix(4,4) == 1
                % Orthographic projection matrix.
                % See https://uk.mathworks.com/help/matlab/creating_plots/understanding-view-projections.html
                top = ( 1 - obj.projectionMatrix(4,2) ) / ...
                    obj.projectionMatrix(2,2);
                fov = atand( top ) * 2;
                set( ax, "DataAspectRatio", [1 1 1], ...
                         "Projection", "orthographic", ...
                         "CameraPosition", obj.t, ...
                         "CameraTarget", obj.t - obj.R(3,:), ...
                         "CameraUpVector", obj.R(2,:), ...
                         "CameraViewAngle", fov )
            end
        end
    end

    methods(Access=private)
        function updateplots( obj )
            %UPDATEPLOTS Update the camera, frame, and field-of-view plots, 
            % if they exist. Called when the Camera properties change, 
            % e.g., if the camera moves.
            
            % Remove deleted graphics objects from plotHandles property.
            obj.plotHandles.camera( ...
                ~isgraphics( obj.plotHandles.camera ) ) = [];
            obj.plotHandles.fov( ~isgraphics( obj.plotHandles.fov ) ) = [];
            deletedFrames = ~all( isgraphics( obj.plotHandles.frame ), 2 );
            % Delete the whole frame if only part of it is valid.
            delete( obj.plotHandles.frame(deletedFrames,:) )
            obj.plotHandles.frame(deletedFrames,:) = [];

            % Update each plot.
            for i = 1 : numel( obj.plotHandles.camera )
                obj.updatecamera( obj.plotHandles.camera(i) )
            end
            for i = 1 : size( obj.plotHandles.frame, 1 )
                obj.updateframe( obj.plotHandles.frame(i,:) )
            end
            for i = 1 : numel( obj.plotHandles.fov )
                obj.updatefov( obj.plotHandles.fov(i) )
            end
        end
        function updatecamera( obj, h )
            %UPDATECAMERA Update a camera plot.
            %
            % INPUTS
            %   h   Handle to an existing camera graphics object, created 
            %        by plotcamera. Scalar Patch object.
            
            % Vertices of the default position are stored in UserData.
            defaultVertices = h.UserData;
            % Rotate the vertices to position the camera's pose.
            h.Vertices = defaultVertices * obj.R + obj.t;
        end
        function updateframe( obj, h )
            %UPDATEFRAME Update a frame plot.
            %
            % INPUTS
            %   h   Handle to an existing frame, created by plotframe. 
            %        1-by-6 graphics object array holding 3 Quiver objects 
            %        and 3 Text objects, in the form 
            %        [quiverX quiverY quiverZ textX textY textZ].
            %
            basisVectorLengths = h(1:3).UserData;
            basisVectors = obj.R .* basisVectorLengths;
            set( h(1:3), ...
                { 'XData', 'YData', 'ZData' }, num2cell( obj.t ), ...
                { 'UData', 'VData', 'WData' }, num2cell( basisVectors ), ...
                { 'Color'                   }, { 'r'; 'g'; 'b' } )
            textPosition = obj.t + basisVectors;
            set( h(4:6), { 'Position' }, num2cell( textPosition, 2 ) )
        end
        function updatefov( obj, h )
            %UPDATEFOV Update a field-of-view plot.
            %
            % INPUTS
            %   h   Handle to an existing field-of-view graphics 
            %        object, created by plotfov. Scalar Patch object.
            %
            dist = h.UserData;
            % Project points from the corners of the image to find the 
            % edges of the field-of-view.
            cornerPixels = [ 1 1; obj.imageSize(1) 1; ...
                           obj.imageSize; 1 obj.imageSize(2) ];
            if obj.projectionMatrix(4,4) == 0
                % Perspective projection matrix.
                directions = raycast( obj, cornerPixels, false );
                % Raycast gives direction vectors on the near plane.
                nearPlaneDist = obj.projectionMatrix(4,3) / ...
                    ( obj.projectionMatrix(3,3) - 1 );
                edgeRaysToDist = directions * dist / nearPlaneDist;
                h.Vertices = [ obj.t; obj.t + edgeRaysToDist ];
            else % obj.projectionMatrix(4,4) == 1
                % Orthographic projection matrix.
                [ directions, sources ] = ...
                    raycast( obj, cornerPixels, true );
                % Raycast gives direction vectors with distance 1.
                edgeRaysToDist = directions .* dist;
                h.Vertices = [ sources; sources + edgeRaysToDist ];
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
            %               whether the matrix is sufficiently close to 
            %               right-handed. By default, 1e-4.
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
            %        of x are valid graphics parent objects.
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
            %         of ax are valid Axes objects.
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