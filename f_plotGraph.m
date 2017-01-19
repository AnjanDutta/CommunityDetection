function [ ] = f_plotGraph( G )
%F_PLOTGRAPH Plots a graph

    % Create 2-dimensional coordinates for each AVPN (marriage) for plotting
    
    ids_marriage = G.node_attrbs_field('idMarriage') ;
    uniq_ids_marriage = unique(ids_marriage);
    [~, locb] = ismember(ids_marriage, uniq_ids_marriage) ;
    
    years = str2double(cellfun(@(x) x(1:4), uniq_ids_marriage, 'UniformOutput', false)) ;
    uniq_years = unique(years)' ;
    
    x = zeros(length(uniq_ids_marriage),1) ;

    for iy = uniq_years
        idx = find(years == iy) ;
        x(idx) = 1:length(idx) ;
    end;

    vertices = [x, years] ;
    vertices = vertices(locb, :) ;

    es_or_ma = G.node_attrbs_field('idCouple') ;

    z(strcmp(es_or_ma, 'MA')) = 1 ;
    z(strcmp(es_or_ma, 'ES')) = 2 ;

    vertices(:,1) = 10*vertices(:,1) + z' ;


    plot(vertices(:,1), vertices(:,2), 'r*','MarkerSize', 5);

    hold on;

    if isfield(G, 'A_marriages')
        [x, y] = gplot(G.A_marriages, vertices) ;
        plot(x, y, 'm-', 'Linewidth', 1) ;
    end

    if isfield(G, 'A_marit')
        [x, y] = gplot(G.A_marit, vertices) ;
        plot(x, y, 'g-', 'Linewidth', 1) ;
    end
    
    if isfield(G, 'A_esposa')
        [x, y] = gplot(G.A_esposa, vertices) ;
        plot(x, y, 'b-', 'Linewidth', 1) ;
    end

    set(gca, 'Ydir', 'reverse') ;
    
end

