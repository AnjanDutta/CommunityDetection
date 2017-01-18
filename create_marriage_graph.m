function [] = create_marriage_graph()

dir_dataset = '/home/adutta/Workspace/5CofM/Dataset/' ;
dir_matchings = '/home/adutta/Workspace/5CofM/Matchings/' ;

filenames_records = dir(fullfile(dir_dataset, '*.csv')) ;
filenames_records = {filenames_records.name} ;

attrbs_nodes = {} ; % Attributes for esposa 
attrbs_marriages = {} ; % Attributes for marriage
edges_marriages = [] ;

for ifile = 1:length(filenames_records)
    fid = filenames_records{ifile} ;
    filename = fullfile(dir_dataset, fid) ;
    fprintf('Processing %s.\n', fid) ;
    fp = fopen(filename, 'rt') ;
    
    % Check empty file; if non-empty, then proceed
    
    if fseek(fp, 1, 'bof') ~= -1
        
        frewind(fp) ;
        header = fgetl(fp) ;
        
        % Need to get off the leading space of the header string
%         header = strtrim(header) ; It doesn't work
        header(1) = [] ; % bad practice, should be replaced
        
        num_fields = length(strfind(header, ';'))+1 ;
        formatSpec = [repmat('%s ', 1, num_fields-1) , '%s'] ;
        
        information = textscan(header, formatSpec, 'Delimiter', {';'}) ;
        information = [information{:}] ;
        
        C = textscan(fp, formatSpec, 'Delimiter', {';'}) ;
        
        % Join all the cells
        C = [C{:}] ;
        
        % Compulsary fields
        comp_fields_ma = { 'AVPN', 'MA_NM_HA', 'MA_C1_HA' } ;
        comp_fields_es = { 'AVPN', 'ES_NM_HA' } ;
        
        % Optional fields
        opt_fields_ma = { 'MA_EC_LI', 'MA_OC_NO', 'MA_RE_HA', ...
            'PM_NM_HA', 'PM_C1_HA', 'PM_OC_NO', 'MM_NM_HA' } ;
        opt_fields_es = { 'ES_C1_HA' , 'ES_EC_LI', '', '', ...
            'PE_NM_HA', 'PE_C1_HA', 'PE_OC_NO', 'ME_NM_HA' } ;
        
        % Compulsory fields for marriage
        required_fields_marriage = {'ANYY', 'IMPOST_LI'} ;
        
        % Fields of interests
        required_fields_ma = [ comp_fields_ma , opt_fields_ma ] ;
        required_fields_es = [ comp_fields_es , opt_fields_es ] ;
        
        % Remove illegible fields from the Compulsory
        comp_fields_idx = ismember(information, [comp_fields_ma, comp_fields_es]) ;
        compulsory_fields = C(:, comp_fields_idx) ;
        rm_registers = any( strcmpi( compulsory_fields , '') | ...
            strcmpi( compulsory_fields , 'illegible') , 2 ) ;
        
        C(rm_registers, :) = [];
                
        % Find required fields        
        idx_fields_ma = ismember(information, required_fields_ma) ;        
        idx_fields_es = ismember(information, required_fields_es) ;        
        idx_fields_marriage = ismember(information, required_fields_marriage) ;
        
        % Node creation
        attrbs_ma = C(: , idx_fields_ma) ;
        attrbs_ma(:,1) = strcat(attrbs_ma(:,1), repmat('_MA',size(attrbs_ma,1), 1)) ;
        attrbs_es = C(: , idx_fields_es) ;
        attrbs_es(:,1) = strcat(attrbs_es(:,1), repmat('_ES',size(attrbs_es,1), 1)) ;
        
        % Add empty columns for optional fields
        empt_c = repmat({''}, size(attrbs_ma,1), 1 ) ;
        c_add = find(strcmpi(required_fields_ma,'')) ;
        for c = c_add
            attrbs_ma = [ attrbs_ma(:,1:c-1) empt_c attrbs_ma(:,c:end) ];
        end;
        
        c_add = find(strcmpi(required_fields_es,'')) ;
        for c = c_add
            attrbs_es = [ attrbs_es(:,1:c-1) empt_c attrbs_es(:,c:end) ];
        end;
                
        % Create marriage edges
        n_marriages = size(attrbs_ma);
        idx_marriages = size(attrbs_nodes, 1) + [ 1:n_marriages ; n_marriages+1:n_marriages*2 ]';
        edges_marriages = [edges_marriages; idx_marriages] ;
        
        % Create the nodes
        attrbs_nodes = [attrbs_nodes; attrbs_ma; attrbs_es] ;
        
        % Fields for the edges
        attrbs_marriages = [attrbs_marriages ; C(:,idx_fields_marriage)] ;
        
    end;
    
    fclose(fp) ;
    
end;

A_marriages = sparse( edges_marriages(:,1) , edges_marriages(:,2) , 1 , size(attrbs_nodes, 1) , size(attrbs_nodes, 1) ) ;
A_marriages = A_marriages | A_marriages' ;
% 
% draw_graphs_from_adjmat( A ) ;

filenames_matchings = dir(fullfile(dir_matchings, '*.csv')) ;
filenames_matchings = {filenames_matchings.name} ;
ids_marriage_es = {} ;
ids_marriage_ma = {} ;

for ifile = 1:length(filenames_matchings)
    fid = filenames_matchings{ifile};
    filename = fullfile(dir_matchings, fid) ;
    fprintf('Processing %s.\n', fid) ;
    fp = fopen(filename, 'rt') ;
    % Check empty file
    
    if fseek(fp, 1, 'bof') ~= -1
        frewind(fp);
        header = fgetl(fp) ;

        num_fields = length(strfind(header,';'))+1;
        formatSpec = [repmat('%s ', 1, num_fields-1) , '%s'];

        information = textscan(header,formatSpec, 'Delimiter', ';');
        information = [information{:}];

        C = textscan(fp,formatSpec, 'Delimiter', ';') ;
        
        % Join all the cells
        C = [C{:}] ;
        if(isempty(C))
            continue ;
        end;
        
        idx = any([strcmp(C(:,3),'illegible'), strcmp(C(:,4),'illegible'),...
            strcmp(C(:,5),'illegible'), strcmp(C(:,6),'illegible'),...
            strcmp(C(:,7),'illegible'), strcmp(C(:,8),'illegible'),...
            strcmp(C(:,9),'illegible'), strcmp(C(:,10),'')], 2) ;

        % Fields of interest
        avpn1 = strcmpi(information, 'AVPN 1');
        avpn2 = strcmpi(information, 'AVPN 2');
        similarity = strcmpi(information, '');

        % Parse filename to know if it is from ESposa or MArit
        [~, fid, ~] = fileparts(fid);
        person = textscan(fid,'%s %s %s %s', 'Delimiter', '_') ;
        person = person{end}{1};

        % Save the information
        switch lower(person)
            case 'es'
                ids_marriage_es = [ids_marriage_es; [C(~idx,avpn1) C(~idx,avpn2) C(~idx,similarity)]] ;
            case 'ma'
                ids_marriage_ma = [ids_marriage_ma; [C(~idx,avpn1) C(~idx,avpn2) C(~idx,similarity)]] ;
            otherwise
                error('Not a correct person')
        end
    end
    fclose(fp) ;
end;

% Esposa
disp('ESPOSA') ;
id_me = [];
id_pe = [];
id_es = [];
es_unique = unique(ids_marriage_es(:,2));
for es_id = es_unique'
    idx_repeated = strcmpi(es_id, ids_marriage_es(:,2));
    ids = ids_marriage_es(idx_repeated,:);
    id_sim = cellfun(@str2num, ids(:,end));
    [~, max_pos] = max(id_sim);
    
    id_me = [id_me; strcat(ids(max_pos,1),'_ES')] ;
    id_pe = [id_pe; strcat(ids(max_pos,1),'_MA')] ;
    id_es = [id_es; strcat(ids(max_pos,2),'_ES')] ;
    
%     id_me = find(strcmp(strcat(ids(max_pos,1),'_ES'), attrbs_nodes)) ;
%     id_pe = find(strcmp(strcat(ids(max_pos,1),'_MA'), attrbs_nodes)) ;
%     id_es = find(strcmp(strcat(ids(max_pos,2),'_ES'), attrbs_nodes)) ;  
%     edges_esposa = [edges_esposa; [id_me, id_es;id_pe, id_es]] ;
end ;

[~, idx_me] = ismember(id_me, attrbs_nodes) ;
[~, idx_pe] = ismember(id_pe, attrbs_nodes) ;
[~, idx_es] = ismember(id_es, attrbs_nodes) ;

idx_comm = all([idx_me, idx_pe, idx_es], 2) ;
idx_me = idx_me(idx_comm) ;
idx_pe = idx_pe(idx_comm) ;
idx_es = idx_es(idx_comm) ;

edges_esposa = [idx_me idx_es;idx_pe idx_es] ;

A_esposa = sparse(edges_esposa(:,1), edges_esposa(:,2), 1, size(attrbs_nodes, 1) , size(attrbs_nodes, 1) ) ;

% Marit
disp('MARIT') ;
id_mm = [] ;
id_pm = [] ;
id_ma = [] ;
ma_unique = unique(ids_marriage_ma(:,2));
for ma_id = ma_unique'
    idx_repeated = strcmpi(ma_id , ids_marriage_ma(:,2));
    ids = ids_marriage_ma(idx_repeated,:);
    id_sim = cellfun(@str2num, ids(:,end));
    [~, max_pos] = max(id_sim);
    
    id_mm = [id_mm; strcat(ids(max_pos,1),'_ES')] ;
    id_pm = [id_pm; strcat(ids(max_pos,1),'_MA')] ;
    id_ma = [id_ma; strcat(ids(max_pos,2),'_MA')] ;   
    
end ;

[~, idx_mm] = ismember(id_mm, attrbs_nodes) ;
[~, idx_pm] = ismember(id_pm, attrbs_nodes) ;
[~, idx_ma] = ismember(id_ma, attrbs_nodes) ;

idx_comm = all([idx_mm, idx_pm, idx_ma], 2) ;
idx_mm = idx_mm(idx_comm) ;
idx_pm = idx_pm(idx_comm) ;
idx_ma = idx_ma(idx_comm) ;

edges_marit = [idx_mm idx_ma;idx_pm idx_ma] ;

A_marit = sparse(edges_marit(:,1), edges_marit(:,2), 1, size(attrbs_nodes, 1) , size(attrbs_nodes, 1) ) ;

disp('PLOT')

ids_marriage = cellfun(@(x) x(1:end-3), attrbs_nodes(:,1), 'UniformOutput', false) ;

uniq_ids_marriage = unique(ids_marriage) ;
[~, locb] = ismember(ids_marriage, uniq_ids_marriage) ;

% nmarriages = length(uniq_ids_marriage) ;
% edges = reshape(ic, size(ids_marriage(:,1:2))) ;
% E = sparse(edges(:,1), edges(:,2), [ids_marriage{:,3}], nmarriages, nmarriages) ;
% 
% Create 2-dimensional coordinates for each AVPN (marriage) for plotting

years = str2double(cellfun(@(x) x(1:4), uniq_ids_marriage, 'UniformOutput', false)) ;
uniq_years = unique(years)' ;
x = zeros(length(uniq_ids_marriage),1) ;

for iy = uniq_years
    idx = find(years == iy) ;
    x(idx) = 1:length(idx) ;
end;

vertices = [x, years] ;
vertices = vertices(locb, :) ;

es_or_ma = cellfun(@(x) x(end-1:end), attrbs_nodes(:,1), 'UniformOutput', false) ;

z(strcmp(es_or_ma, 'MA')) = 1 ;
z(strcmp(es_or_ma, 'ES')) = 2 ;

vertices(:,1) = 10*vertices(:,1) + z' ;

% vertices = [vertices, z'] ;
% 
% % Plot the big graph
plot(vertices(:,1), vertices(:,2), 'r*','MarkerSize', 5);

hold on;

[x, y] = gplot(A_marriages, vertices) ;
plot(x, y, 'm-', 'Linewidth', 1) ;

[x, y] = gplot(A_marit, vertices) ;
plot(x, y, 'g-', 'Linewidth', 1) ;

[x, y] = gplot(A_esposa, vertices) ;
plot(x, y, 'b-', 'Linewidth', 1) ;

set(gca, 'Ydir', 'reverse') ; 