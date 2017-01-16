function [avpn1, avpn2] = read_marriage_record_limited()

dir_res = './Results/' ;
filenames = dir(fullfile(dir_res, '*.csv')) ;
filenames = {filenames.name} ;
ids_marriage_es = {} ;
ids_marriage_ma = {} ;

for ifile = 1:length(filenames)
    fid = filenames{ifile};
    filename = fullfile(dir_res, fid) ;
    fprintf('Processing %s.\n', fid) ;
    fp = fopen(filename, 'rt') ;
    % Check empty file
    
    if fseek(fp, 1, 'bof') ~= -1
        frewind(fp);
        header = fgetl(fp) ;

        num_fields = length(strfind(header,';'));
        formatSpec = [repmat('%s ', 1, num_fields-1) , '%s'];

        information = textscan(header,formatSpec, 'Delimiter', ';');
        information = [information{:}];

        C = textscan(fp,formatSpec, 'Delimiter', ';') ;
        idx = any([strcmp(C{3},'illegible'), strcmp(C{4},'illegible'),...
            strcmp(C{5},'illegible'), strcmp(C{6},'illegible'),...
            strcmp(C{7},'illegible'), strcmp(C{8},'illegible')], 2) ;  

        % Fields of interest
        avpn1 = strcmpi(information, 'AVPN 1');
        avpn2 = strcmpi(information, 'AVPN 2');
        similarity = strcmpi(information, 'Similitud');

        % Parse filename to know if it is from ESposa or MArit
        [~, fid, ~] = fileparts(fid);
        person = textscan(fid,'%s %s %s %s', 'Delimiter', '_') ;
        person = person{end}{1};

        % Save the information
        switch lower(person)
            case 'es'
                ids_marriage_es = [ids_marriage_es; [C{avpn1}(~idx) C{avpn2}(~idx) C{similarity}(~idx)]] ;
            case 'ma'
                ids_marriage_ma = [ids_marriage_ma; [C{avpn1}(~idx) C{avpn2}(~idx) C{similarity}(~idx)]] ;
            otherwise
                error('Not a correct person')
        end
    end
    fclose(fp) ;
end;

ids_marriage = {};

% Esposa
disp('ESPOSA')
es_unique = unique(ids_marriage_es(:,2));
for es_id = es_unique'
    idx_repeated = strcmpi(es_id , ids_marriage_es(:,2));
    ids = ids_marriage_es(idx_repeated,:);
    id_sim = cellfun(@str2num, ids(:,end));
    [~, max_pos] = max(id_sim);
    ids_marriage = [ids_marriage; ids(max_pos,1:2), 1] ;
end

% Marit
disp('MARIT')
ma_unique = unique(ids_marriage_ma(:,2));
for ma_id = ma_unique'
    idx_repeated = strcmpi(ma_id , ids_marriage_ma(:,2));
    ids = ids_marriage_ma(idx_repeated,:);
    id_sim = cellfun(@str2num, ids(:,end));
    [~, max_pos] = max(id_sim);
    ids_marriage = [ids_marriage; ids(max_pos,1:2), 2] ;
end


disp('Plot')
[uniq_ids_marriage, ~, ic] = unique(ids_marriage(:,1:2)) ;
nmarriages = length(uniq_ids_marriage) ;
edges = reshape(ic, size(ids_marriage(:,1:2))) ;
E = sparse(edges(:,1), edges(:,2), [ids_marriage{:,3}], nmarriages, nmarriages) ;

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
plot(vertices(:,1), vertices(:,2), 'r*','MarkerSize', 5);

hold on;

[x, y] = gplot(E==1, vertices) ;
plot(x, y, 'b-', 'Linewidth', 1) ;

[x, y] = gplot(E==2, vertices) ;
plot(x, y, 'g-', 'Linewidth', 1) ;

set(gca, 'Ydir', 'reverse') ; 