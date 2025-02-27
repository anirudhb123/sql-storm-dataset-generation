SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND t.production_year IS NOT NULL AND mk.id < 2028444 AND t.episode_of_id IN (1218214, 1465191, 183213, 199710, 376471, 510621, 548169, 590269, 827945);