classdef One_Agent_RealVehicleROS   <   CtSystem

    properties
         
        flag = 0
        vm      % Attacker Velocity Magnitude
        vt      % Target Velocity Magnitude
        target
        attacker_data_subscriber
        attacker_velocity_publisher

    end
    
    methods
        
        function obj = One_Agent_RealVehicleROS(attacker_data_subscriber,...
                                                attacker_velocity_publisher,...
                                                vm,...
                                                target)
            
            obj = obj@CtSystem('nx',7,'nu',1,'ny',7);            
            obj.target = target;
            obj.attacker_data_subscriber = attacker_data_subscriber;            
            obj.attacker_velocity_publisher = attacker_velocity_publisher;
            obj.vm = vm;
        end
        
        function xDot = f(obj,t,x,u,varargin)
            
            % Publisher send u to the vehicle;
            attacker_velocity_Msg = rosmessage(obj.attacker_velocity_publisher);
            attacker_Pose_data = receive(obj.attacker_data_subscriber,10);
            
            o2 = [attacker_Pose_data.X;attacker_Pose_data.Y];
            d = sqrt((obj.target(1)-o2(1))^2+ (obj.target(2)-o2(2))^2);    %distance between target and attacker.
            
            if obj.flag > 2             %to avoid initial random values.
                if (d >= 0.2)                    
                    attacker_velocity_Msg.Linear.X = obj.vm;
                    attacker_velocity_Msg.Angular.Z = double(subs(u(1)));
                else
                    attacker_velocity_Msg.Linear.X = 0;
                    attacker_velocity_Msg.Angular.Z = 0;
                end    
                send(obj.attacker_velocity_publisher,attacker_velocity_Msg);
            end   
            disp('--------publishing--------')
            
            %state equation ...... e.g xDot = Ax + Bu (for linear systems). 
            xDot = [obj.vm*cos(x(3));
                    obj.vm*sin(x(3));
                    u(1);
                    0;
                    0;
                    -obj.vm*cos(x(3)-x(7));
                    -obj.vm*sin(x(3)-x(7))/x(6)];
                
            disp(obj.target);    
        end
        
        function y = h(obj,t,x,varargin)
        
            % Subscriber read position of the vehicle the vehicle;
            attacker_pose_data = receive(obj.attacker_data_subscriber,10);           
            theta = attacker_pose_data.Theta;
            
            % bounding theta of turtle between -pi to pi
            if( theta > 3.14 )
                theta = theta - 2*3.14;
            end
            if( theta < -3.14 )
                theta = theta + 2*3.14;
            end
            
            %state equation ...... e.g, Y = Cx + Du (for linear systems).  
            y = double([attacker_pose_data.X;
                 attacker_pose_data.Y;
                 theta;
                 obj.target(1);
                 obj.target(2);
                 sqrt((obj.target(1) - attacker_pose_data.X)^2 + (obj.target(1) - attacker_pose_data.Y)^2);
                 (atan2((obj.target(2) - attacker_pose_data.Y),(obj.target(1) - attacker_pose_data.X)))]);
             
            disp('---taking output feedback---'); 
            obj.flag = obj.flag + 1;        
        end            
    end    
end