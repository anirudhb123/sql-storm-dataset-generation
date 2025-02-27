SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mk.id > 190813 AND mk.keyword_id < 77177 AND k.keyword LIKE '%li%' AND t.episode_nr IN (10597, 13285, 14252, 448, 6853, 7894, 8);