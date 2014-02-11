function [mpc, t, t2, DG, UG, branchmap] = mst(mpc),
    r = runpf(mpc);
    r = ext2int(r);
    n = size(r.bus, 1);
    m = size(r.branch, 1);
    branchmap = sparse(n, n);
    DG = sparse(n, n); % directed graph
    values = -sqrt(sum(r.branch(:,[16 17]).^2,2));
    for line=1:m,
        i = r.branch(line,1);
        j = r.branch(line,2);
        value = values(line);
        prev = branchmap(i,j);
        % if multiple lines connect same two buses, take minimum
        if ~prev || value < values(prev), 
            branchmap(i,j) = line;
            branchmap(j,i) = line;
            DG(i, j) = value;
        end
    end
    UG = tril(DG + DG'); % undirected graph, MST function needs this
    t2 = graphminspantree(UG, 'Method', 'Kruskal');
    [i,j] = find(t2);
    t = full(branchmap(sub2ind([n n],i,j)));
    %sort(t)'
    %t = r.order.branch.i2e(t);
    mpc.branch = mpc.branch(t, :);
