function [avpn1, avpn2] = read_marriage_record()

dir_res = '/home/adutta/Workspace/5CofM/Results/' ;
filenames = dir(fullfile(dir_res, '*.csv')) ;
filenames = {filenames.name} ;
ids_marriage = {} ;

for ifile = 1:length(filenames)
    filename = fullfile(dir_res, filenames{ifile}) ;
    fprintf('Processing %s.\n', filenames{ifile}) ;
    fp = fopen(filename, 'rt') ;
    garbage = fgetl(fp) ;
    C = textscan(fp,'%s %s %s %s %s %s %s %s %s', 'Delimiter', ';') ;
    fclose(fp) ;
    idx = any([strcmp(C{3},'illegible'), strcmp(C{4},'illegible'),...
        strcmp(C{5},'illegible'), strcmp(C{6},'illegible'),...
        strcmp(C{7},'illegible'), strcmp(C{8},'illegible')], 2) ;    
    ids_marriage = [ids_marriage; [C{1}(~idx) C{2}(~idx)]] ;
end;

[uniq_ids_marriage, ~, ic] = unique(ids_marriage) ;
nmarriages = length(uniq_ids_marriage) ;
edges = reshape(ic, size(ids_marriage)) ;
E = sparse(edges(:,1), edges(:,2), 1, nmarriages, nmarriages) ;

% Create 2-dimensional coordinates for each AVPN (marriage) for plotting

years = str2double(cellfun(@(x) x(1:4), uniq_ids_marriage, 'UniformOutput', false)) ;
uniq_years = unique(years)' ;
x = zeros(length(uniq_ids_marriage),1) ;
for iy = uniq_years
    idx = find(years == iy) ;
    x(idx) = 1:length(idx) ;
end;
vertices = [x, years] ;

% Plot the big graph

[x, y] = gplot(E, vertices) ;
plot(x, y, 'bo-', 'Linewidth', 2, 'MarkerSize', 5, 'MarkerFaceColor', 'r') ;
set(gca, 'Ydir', 'reverse') ; 