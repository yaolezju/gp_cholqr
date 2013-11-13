function OptState = cholqr_discrete_one_pass(OptState, GPModel, trainx, trainy)
  
 
    
    data_var = GPModel.kern.extract_data_var(OptState.hyp);
    noise_var = GPModel.kern.extract_noise_var(OptState.hyp);
    kern_hyp = GPModel.kern.extract_kern_hyp(OptState.hyp);
    
    OptState = prepareOptStateKFuncs(OptState, GPModel, trainx, data_var, kern_hyp);
  
    
 
    [OptState.G, OptState.Q, OptState.R, OptState.D, OptState.Dadv]...
                          = cholQRBatchCompute( OptState.size_params,...
                                                trainx,...
                                                OptState.K , ...
                                                OptState.diagK  ,...
                                                OptState.P, ...
                                                noise_var, ...
                                                false);


    if GPModel.cholqr.swap_info_pivots
        %this is run once per epoch only, different from the InfoRevisit that might run
        %from within cholQRSwapUpdate, which is run multiple times within one
        %epoch 
        %the [] argument for RIPParams is intentional!!!!
        [OptState.P, OptState.G, OptState.Q, OptState.R, OptState.Dadv, ...
            OptState.D, OptState.usedInfoPInds] = ...
                            cholQRRevisitInfoPivots(OptState.size_params,...
                                                    trainx,...
                                                    OptState.K,...
                                                    OptState.P, ...
                                                    OptState.G, ...
                                                    OptState.Q, ...
                                                    OptState.R, ...
                                                    OptState.Dadv, ...
                                                    noise_var, ...
                                                    OptState.D, ...
                                                    OptState.usedInfoPInds,...
                                                    []);
    end
   
            
    if isfield(GPModel.cholqr,'use_cache') &&  GPModel.cholqr.use_cache
        [OptState.QGG, OptState.infoQ, OptState.infoR] ...
                            = cacheValueBatchCompute(OptState.size_params,...
                                                     OptState.Q, ...
                                                     OptState.G);
    else
        OptState.QGG   = [];
        OptState.infoQ = [];
        OptState.infoR = [];
    end

%             GPModel.cholqr.num_info_revisit = OptState.num_info_revisit;

    [OptState.P,~,~,~,~,~,~,~,~,OptState.usedInfoPInds, ...
        OptState.pred_pivots_ages, OptState.size_params, GPModel.cholqr] = ...
                                 cholQRRevisit( OptState.size_params, ...
                                                trainx,...
                                                OptState.diagK, ...
                                                OptState.K, ...
                                                trainy, ...
                                                OptState.P, ...
                                                OptState.G, ...
                                                OptState.Q, ...
                                                OptState.R, ...
                                                OptState.Dadv, ...
                                                OptState.QGG, ...
                                                OptState.infoQ, ...
                                                OptState.infoR, ...
                                                OptState.D, ...
                                                noise_var, ...
                                                OptState.usedInfoPInds,...
                                                OptState.pred_pivots_ages,...
                                                GPModel.cholqr,...
                                                GPModel.cholqr.do_var_cost);

%             OptState.num_info_revisit = GPModel.cholqr.num_info_revisit;

 
    
    OptState.I = OptState.P(1:GPModel.m);
end