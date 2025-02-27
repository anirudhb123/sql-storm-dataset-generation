SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND t.md5sum IN ('139de322246741594fc92f83e8f1c976', '1426bc5fb685e2a7982b2c9034ae61db', '2f811a29b829a508016381d3d0bf480f', '6617687c34254b46bd2d2ff8d9278c12', '6a41ecba7258a4105b1eff3156eedd10', 'a835840d193b7852725bbbfa09dfa8a3');