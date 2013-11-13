function [P, G, Q, R, Dadv, QGG, infoQ, infoR, D, usedInfoPInds, pp_age, size_params, RIPParams] = ...
                                          cholQRRevisit(size_params,...
                                                        trainx,...
                                                        diagK,...
                                                        K,...
                                                        Y, ...
                                                        P, ...
                                                        G, ...
                                                        Q, ...
                                                        R, ...
                                                        Dadv, ...
                                                        QGG,...
                                                        infoQ,...
                                                        infoR,...
                                                        D, ...
                                                        noise_var, ...
                                                        usedInfoPInds,...
                                                        pp_age,...
                                                        RIPParams,...
                                                        do_var_cost)


if ~exist('do_var_cost','var')
    do_var_cost = false;
end


k = size_params.k;
% n = size_params.n;
% kadv = size_params.kadv;
% delta = size_params.delta;
% m = size_params.m;

if isfield(RIPParams, 'max_swap_per_epoch') && RIPParams.max_swap_per_epoch ~= k-1
    tot_swap_num = RIPParams.max_swap_per_epoch;
    
    tmp_pp_age = pp_age;
    swap_candidates = find(pp_age == max(tmp_pp_age));
    swap_candidates = swap_candidates(randperm(numel(swap_candidates)));
    tmp_pp_age(swap_candidates) = 0;
    
    while numel(swap_candidates) < tot_swap_num
        tmp_candidates = find(pp_age == max(tmp_pp_age));
        tmp_candidates = tmp_candidates(randperm(numel(tmp_candidates)));
        
        swap_candidates = [swap_candidates ; tmp_candidates];
        if numel(swap_candidates) > tot_swap_num
            swap_candidates = swap_candidates(1:tot_swap_num);
        end
        tmp_pp_age(swap_candidates) = 0;
    end
    
    swap_candidates = swap_candidates(1:tot_swap_num);
    swap_inds = P(swap_candidates(randperm(tot_swap_num)));
    
else
    
    tot_swap_num = k-1;
 
    if isfield(RIPParams,'random_swap_order') && RIPParams.random_swap_order 
        swap_inds = P(randperm(tot_swap_num));    
    else
        swap_inds = P(tot_swap_num:-1:1);
    end
end

if ~isempty(pp_age)
    pp_age = pp_age + 1;
end
 
RIPParams = cholQRReinfoSetupPreSchedule(P,k,RIPParams);
 
RIPParams.RIP_count = 0;

for ik = 1:tot_swap_num
    size_params.ik_swap = find(P == swap_inds(ik));
    assert(size_params.ik_swap < k);
 
    [P, G, Q, R, Dadv, QGG, infoQ, infoR, D, usedInfoPInds, pp_age, RIPParams, size_params] = ...
                                               cholQRSwapUpdate(size_params, ...
                                                                Y,...
                                                                P,...
                                                                trainx,...
                                                                diagK,...
                                                                K,...
                                                                G,... 
                                                                Q,...
                                                                R,...
                                                                Dadv, ...
                                                                QGG,...
                                                                infoQ,...
                                                                infoR,...
                                                                noise_var,...
                                                                D,...
                                                                usedInfoPInds,...
                                                                pp_age,...
                                                                RIPParams,...
                                                                do_var_cost);
    
end
% new_sis = P(1:k);
% figure(1);
% subplot(2,1,1)
% hist(pp_age);
% subplot(2,1,2)
% bar(pp_age);
% drawnow;
 

end