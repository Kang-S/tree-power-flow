function casefile = mst_convert(casefile),
    mpc = loadcase(casefile);
    mpc_tree = mst(mpc);
    savecase(strcat(casefile(1:end-2), '_tree.m'), mpc_tree);
end
