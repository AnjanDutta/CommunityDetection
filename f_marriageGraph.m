function [ G ] = f_marriageGraph( dir_dataset )
%F_MARRIAGEGRAPH Creates a marriage graph
%   Recieve a folder of csv file where each line is a register. It reads it
%   and creatse a graph where each node is a person and each connection a
%   marriage.
%       Usage: f_marriageGraph( './Datasets/' )
%       Output:    * G.node_attrs        -> Node attributes
%                  * G.A_marriages       -> Adjacency matrix for marriages
%                  * G.attrbs_marriages  -> Marriages attributes
%                       
%                  * G.node_attrbs_field(name) -> Value of "name" for
%                   all the nodes
%                  * G.node_i_attrbs_field(i, name) -> Value of "name" for
%                   node "i"
%                  * G.attrbs_marriages_ij(i, j)    -> If exist an edge,
%                   value of the attributes between nodes "i" and "j"   
    
    if nargin ~= 1
        dir_dataset = './Datasets/' ; % Dataset
    end

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

            % Need to get off the leading space of the header string, Byte
            % Order Mark
            header(1) = [] ; % bad practice, should be replaced

            num_fields = length(strfind(header, ';')) ;
            formatSpec = [repmat('%s ', 1, num_fields) , '%s'] ;

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
            attrbs_ma = [attrbs_ma(:,1) , repmat({'MA'},size(attrbs_ma,1), 1) , attrbs_ma(:,2:end)] ;
            attrbs_es = C(: , idx_fields_es) ;
            attrbs_es = [attrbs_es(:,1) , repmat({'ES'},size(attrbs_es,1), 1) , attrbs_es(:,2:end)] ;
            
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
            n_marriages = size(attrbs_ma,1);
            idx_marriages = size(attrbs_nodes, 1) + [ 1:n_marriages ; n_marriages+1:n_marriages*2 ]';
            edges_marriages = [edges_marriages; idx_marriages] ;

            % Create the nodes
            attrbs_nodes = [attrbs_nodes; attrbs_ma; attrbs_es] ;

            % Fields for the edges
            attrbs_marriages = [attrbs_marriages ; C(:,idx_fields_marriage)] ;

        end;

        fclose(fp) ;

    end;

    % Adjacency matrix for the Marriages
    A_marriages = sparse( edges_marriages(:,1) , edges_marriages(:,2) , 1:size(edges_marriages,1) , size(attrbs_nodes, 1) , size(attrbs_nodes, 1) ) ;
    A_marriages = A_marriages + A_marriages' ;

    % Create the Graph
    G.node_attrbs_names = { 'idMarriage' , 'idCouple' , 'name', 'surname' , 'civil_status' , 'occupation'...
        , 'residency' , 'father_name' , 'father_surname' , 'father_occupation'...
        , 'mother_name' } ;
    G.node_attrbs = attrbs_nodes;
    G.attrbs_marriages = attrbs_marriages ;
    G.A_marriages = A_marriages ;
    
    
    G.node_attrbs_field = @(name) G.node_attrbs(:, strcmpi(G.node_attrbs_names, name));
    G.node_i_attrbs_field = @(i , name) G.node_attrbs(i, strcmpi(G.node_attrbs_names, name));
    G.attrbs_marriages_ij = @(i , j) G.attrbs_marriages(:, G.A_marriages(i,j));
end

