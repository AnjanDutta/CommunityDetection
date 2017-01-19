% Crates marriage graph for BH2M
dir_dataset = './Datasets/' ;
dir_matchings = './Matchings/' ;
% Marriage Graph
disp('Marriage Graph')
[ G ] = f_marriageGraph( dir_dataset );
%f_plotGraph( G )

% Descendants Matching
disp('Marriage Graph')
[ G ] = f_descendanceGraph( G , dir_matchings );
f_plotGraph( G )
