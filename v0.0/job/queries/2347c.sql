SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND t.episode_nr < 8225 AND mk.keyword_id < 22930 AND t.season_nr IN (6) AND t.id > 757084 AND mi_idx.info < '.0...043.0' AND t.md5sum < '52678cd68dc1128fe5cc2b3cde199a86';