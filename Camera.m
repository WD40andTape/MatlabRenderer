classdef Camera < matlab.mixin.Copyable
    properties (Access = public)
        projectionMatrix (4,4) { mustBeFloat } % Row-major
        imageSize (1,2) { mustBeInteger, mustBePositive } = [100 100] % [width height]
        t (1,3) { mustBeNumeric, mustBeNonNan } = [0 0 0]
        R (3,3) { mustBeRightHanded } = [1 0 0; 0 -1 0; 0 0 -1] % Row-major
        plotHandles (1,1) struct { mustHaveFields( plotHandles, [ "frame", ...
            "fov", "camera" ] ) } = struct( "frame", gobjects, "fov", ...
            gobjects, "camera", gobjects )
    end
    methods
        function obj = Camera( projectionMatrix, imageSize, t, R )
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
        
        function delete(obj)
            fields = fieldnames(obj.plotHandles);
            for i = 1 : numel( fields )
                delete( obj.plotHandles.(fields{i}) )
            end
        end
        
        function set.projectionMatrix( obj, projectionMatrix )
            obj.projectionMatrix = projectionMatrix;
            obj.updatePlots()
        end
        function set.imageSize( obj, imageSize )
            obj.imageSize = imageSize;
            obj.updatePlots()
        end
        function set.t( obj, t )
            obj.t = t;
            obj.updatePlots()
        end
        function set.R( obj, R )
            obj.R = R;
            obj.updatePlots()
        end
        
        function plotFrame( obj, ax, len )
            arguments
                obj
                ax (1,1) { mustBeAxes( ax ) } = gca
                len (1,1) { mustBePositive } = 1
            end
            %
            if any( ~isgraphics( obj.plotHandles.frame) )
                if isfield(obj.plotHandles,"frame")
                    delete(obj.plotHandles.frame)
                end
                % Match the behaviour of patch, used by the other 
                % plotting functions, in not clearing the axes.
                holdState = get(ax, "NextPlot");
                set(ax, "NextPlot", "add");
                h = quiver3([],[],[],[],[],[],"Parent",ax,"Color","r");
                h = [h quiver3([],[],[],[],[],[],"Parent",ax,"Color","g")];
                h = [h quiver3([],[],[],[],[],[],"Parent",ax,"Color","b")];
                set(h,"AutoScale","off","LineWidth",2,"MaxHeadSize",0.4)
                h = [h text(ax,0,0,0,"")];
                h = [h text(ax,0,0,0,"")];
                h = [h text(ax,0,0,0,"")];
                set(ax, "NextPlot", holdState); % restore the state
                obj.plotHandles.frame = h;
            end
            % R is in row-major order, i.e. the rows of R denote its vectors
            xAxis = obj.R(1,:) .* len;
            yAxis = obj.R(2,:) .* len;
            zAxis = obj.R(3,:) .* len;
            % Update positions and labels
            h = obj.plotHandles.frame;
            set(h(1:3),"XData",obj.t(1),"YData",obj.t(2),"ZData",obj.t(3))
            set(h(1),"UData",xAxis(1),"VData",xAxis(2),"WData",xAxis(3))
            set(h(2),"UData",yAxis(1),"VData",yAxis(2),"WData",yAxis(3))
            set(h(3),"UData",zAxis(1),"VData",zAxis(2),"WData",zAxis(3))
            set(h(4),"Position",obj.t+xAxis,"String","X")
            set(h(5),"Position",obj.t+yAxis,"String","Y")
            set(h(6),"Position",obj.t+zAxis,"String","Z")
        end
        
        function plotCamera( obj, ax, len )
            arguments
                obj
                ax (1,1) { mustBeAxes( ax ) } = gca
                len (1,1) { mustBePositive } = 1
            end
            % Camera geometry is from MATLAB's built-in plotCamera.
            ln = 2/3 * len; % body length
            cu = 1/3 * len; % body side
            ro = cu / 2;       % rim offset
            bz = ln + cu;      % rim z offset (extent)
            V = [0 0 bz; 0 cu bz; cu cu bz; cu 0 bz; ... % back
                 0 0 cu; 0 cu cu; cu 0 cu; cu cu cu; ... % front
                 -ro -ro 0; cu+ro -ro 0; cu+ro cu+ro 0; -ro cu+ro 0]; % lens
            V = V - [cu/2 cu/2 cu*2];
            if ~isgraphics( obj.plotHandles.camera )
                F = [1 2 3 4; ... % back
                     1 5 6 2; 1 5 7 4; 4 7 8 3; 3 8 6 2; ... % sides
                     5 9 10 7; 7 10 11 8; 8 11 12 6; 6 12 9 5; ... % rim
                     9 10 11 12]; % lens
                C = [ zeros( size( F, 1 ) - 1, 3 ); 1 1 0 ];
                h = patch( ax, "Faces", F, "Vertices", V, ...
                    "FaceVertexCData", C, "FaceColor", "flat", ...
                    "FaceLighting", "none" );
                h.UserData = len; % Used in updatePlots().
                obj.plotHandles.camera = h;
            end
            obj.plotHandles.camera.Vertices = V * obj.R + obj.t;
        end
        
        function plotFOV( obj, ax, dist )
            % Depends on the seperate function, raycast.
            arguments
                obj
                ax (1,1) { mustBeAxes( ax ) } = gca
                dist (1,1) { mustBePositive } = 1
            end
            if exist( 'raycast', 'file' ) ~= 2
                warning( "plotFOV depends on the raycast function, " + ...
                    "which was not found on the search path." )
                return
            end
            cornerPixels = [ 1 1; obj.imageSize(1) 1; ...
                           obj.imageSize; 1 obj.imageSize(2) ];
            edgeRaysNearPlane = raycast( obj, cornerPixels );
            nearPlaneDist = obj.projectionMatrix(4,3) / ...
                ( obj.projectionMatrix(3,3) - 1 );
            edgeRaysFarPlane = edgeRaysNearPlane * dist / nearPlaneDist;
            fovVertices = [ obj.t; obj.t + edgeRaysFarPlane ];
            if ~isgraphics( obj.plotHandles.fov )
                fovFaces = [ 1 2 3; 1 3 4; 1 4 5; 1 5 2 ];
                h = patch( ax, "Faces", fovFaces, "Vertices", ...
                    fovVertices, "FaceColor", [0 0 0], "FaceAlpha", 0.1 );
                h.UserData = dist; % Used in updatePlots().
                obj.plotHandles.fov = h;
            else
                obj.plotHandles.fov.Vertices = fovVertices;
            end
        end
        
        function updatePlots( obj )
            if all( isgraphics( obj.plotHandles.frame ) )
                h = obj.plotHandles.frame;
                length = norm( [ h(1).UData, h(1).VData, h(1).WData ] );
                plotFrame( obj, h(1).Parent, length );
            end
            if isgraphics( obj.plotHandles.fov )
                plotFOV( obj, obj.plotHandles.fov.Parent, ...
                    obj.plotHandles.fov.UserData );
            end
            if isgraphics( obj.plotHandles.camera )
                plotCamera( obj, obj.plotHandles.frame(1).Parent, ...
                    obj.plotHandles.camera.UserData );
            end
        end
        
        function setView( obj, ax )
            % NOTE: MATLAB's camera will render objects outside of the 
            %   field-of-view (instead this is controlled by axes limits), 
            %   and can only have square pixels. This will lead to slight
            %   differences in the render as compared to a normal 
            %   rasterization method.
            % NOTE: Changing the low-level CameraViewAngle property messes 
            %   with axes positioning within the figure. The axes used for 
            %   this purpose should therefore be in a standalone figure.
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
end