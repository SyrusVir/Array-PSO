classdef SLLCost < Problem
    properties
        freq0 %operating frequency
        Dk %relative permittivity
        dimensions %number of elements
        Ai %feeding coefficients
        dtheta = 0.1
        theta
        tolerance = 1e-10
        element_pattern
        
    end
    
    properties (Constant)
        c = physconst('LightSpeed');
    end
  
    methods (Static)
        %%% CONSTRUCTOR
        function obj = SLLCost(elements,Dk,freq0)
            obj.dimensions = elements;
            obj.theta = 0:obj.dtheta:360;
            obj.element_pattern = ones(numel(obj.theta),1);
            obj.Ai = ones(1,elements+1);
            if (nargin > 1)
                obj.Dk = Dk;
                obj.freq0 = freq0;
            end
        end
    end
        
    methods
        function cost = evaluate(obj, positions)
            if (numel(positions) ~= obj.dimensions) %make sure input has expected number of elements
                cost = inf; %replace with error handling in future?
            else
                AF = obj.getAF(positions,false); %get unnormalized AF
                
                %normalize
                AF_max = max(AF);
                ind_max = find(abs(AF_max - AF) < obj.tolerance); %get indices of global maxes
                %AF = AF./AF_max;
                AF = AF.*obj.element_pattern;
                
                %%% Find SLL Finding
                %Using Valley Finder
                ind_vall = find(islocalmin(abs(AF)));
                n = sort([ind_vall(:); ind_max(:)]); %sorted indices of valleys and main lobe peaks
                null1 = n(find(n == ind_max(1)) + 1); %find valley/null closest to first main lobe
                null2 = n(find(n == ind_max(2)) - 1); %find valley/null closest to rear lobe; SECOND INDEX MAY NOT BET REAR LOBE
                max_SLL = max(AF(null1:null2));
                
%                 %Using Peak Finder
%                 ind_peak = find(islocalmax(abs(AF))); %find indices of peaks (detection may cause problems)
%                 ind_side = setdiff(ind_peak,ind_max); %remove index of max peak; gives indices of side lobe peaks
%                 max_SLL = max(AF(ind_side));
                
                cost = abs(max_SLL);
                
                %Plotting for debug
%                 y = zeros(size(obj.theta));
%                 y(ind_side) = 1;
% 
%                 y1 = zeros(size(obj.theta));
%                 y1(ind_peak) = 1;
% 
%                 figure()
%                 plot((obj.theta), abs(AF),(obj.theta),y, (obj.theta), y1);
            end
        end
       
        
        function set.dtheta(obj,d)
            %Custom set method; every time dtheta is change, automatically
            %update theta vector
            obj.dtheta = d;
            obj.theta = 0:d:360; %#ok<MCSUP>
        end
        
        function AF = getAF(obj,pos,norm)
            %function that returns the (un)normalized array factor
            k = 2*pi/(obj.c/sqrt(obj.Dk)/obj.freq0); %phase constant
            D = [0 pos(:)']; %append 0 for element fixed at origin
            Exp_arr = exp(1i*k*D(:)'.*sin(deg2rad(obj.theta(:)))); %columns are element factors
            AF = Exp_arr*obj.Ai(:);
            
            if nargin>2
                % Treat additional argument after pos as a boolean to
                % return normalized AF
                if norm
                    AF = AF./max(AF);
                end
            end
        end
    end
end