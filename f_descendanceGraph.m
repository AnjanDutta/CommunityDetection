function [ G ] = f_descendanceGraph( G , dir_matchings )
%F_DESCENDANCEGRAPH Summary of this function goes here
%   Detailed explanation goes here
%       Usage: f_descendanceGraph( G , './Matchings/' )

    if nargin ~= 2
        dir_matchings = './Matchings/' ; % Matchings between Datasets files
    end
    
    % Matching between marriages along time
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

            num_fields = length(strfind(header,';'));
            formatSpec = [repmat('%s ', 1, num_fields) , '%s'];

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
    simi = [] ;
    es_unique = unique(ids_marriage_es(:,2));
    for es_id = es_unique'
        idx_repeated = strcmpi(es_id, ids_marriage_es(:,2));
        ids = ids_marriage_es(idx_repeated,:);
        id_sim = cellfun(@str2num, ids(:,end));
        [s, max_pos] = max(id_sim);

        id_me = [id_me; [ids{max_pos,1},'ES']] ;
        id_pe = [id_pe; [ids{max_pos,1},'MA']] ;
        id_es = [id_es; [ids{max_pos,2},'ES']] ;
        simi = [ simi; s ];
    end ;
    
    attrbs_nodes = strcat( G.node_attrbs_field('idMarriage') , G.node_attrbs_field('idCouple') );
    
    [~, idx_me] = ismember(id_me, attrbs_nodes) ;
    [~, idx_pe] = ismember(id_pe, attrbs_nodes) ;
    [~, idx_es] = ismember(id_es, attrbs_nodes) ;
   
    idx_comm = all([idx_me, idx_pe, idx_es], 2) ;
    idx_me = idx_me(idx_comm) ;
    idx_pe = idx_pe(idx_comm) ;
    idx_es = idx_es(idx_comm) ;
    simi = simi(idx_comm) ;
    
    edges_esposa = [idx_me idx_es;idx_pe idx_es] ;
    simi = [simi; simi];

    A_esposa = sparse(edges_esposa(:,1), edges_esposa(:,2), simi, size(attrbs_nodes, 1) , size(attrbs_nodes, 1) ) ;

    % Marit
    disp('MARIT') ;
    id_mm = [] ;
    id_pm = [] ;
    id_ma = [] ;
    simi = [] ;
    ma_unique = unique(ids_marriage_ma(:,2));
    for ma_id = ma_unique'
        idx_repeated = strcmpi(ma_id , ids_marriage_ma(:,2));
        ids = ids_marriage_ma(idx_repeated,:);
        id_sim = cellfun(@str2num, ids(:,end));
        [s, max_pos] = max(id_sim);

        id_mm = [id_mm; [ids{max_pos,1},'ES']] ;
        id_pm = [id_pm; [ids{max_pos,1},'MA']] ;
        id_ma = [id_ma; [ids{max_pos,2},'MA']] ;   
        simi = [ simi; s ];
    end ;

    [~, idx_mm] = ismember(id_mm, attrbs_nodes) ;
    [~, idx_pm] = ismember(id_pm, attrbs_nodes) ;
    [~, idx_ma] = ismember(id_ma, attrbs_nodes) ;

    idx_comm = all([idx_mm, idx_pm, idx_ma], 2) ;
    idx_mm = idx_mm(idx_comm) ;
    idx_pm = idx_pm(idx_comm) ;
    idx_ma = idx_ma(idx_comm) ;
    simi = simi(idx_comm) ;
    
    edges_marit = [idx_mm idx_ma;idx_pm idx_ma] ;
    simi = [simi; simi];
    
    A_marit = sparse(edges_marit(:,1), edges_marit(:,2), simi, size(attrbs_nodes, 1) , size(attrbs_nodes, 1) ) ;
    
    G.A_esposa = A_esposa;
    G.A_marit = A_marit;
    
end

