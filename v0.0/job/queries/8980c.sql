SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND it.id > 12 AND t.episode_of_id IS NOT NULL AND mk.keyword_id IN (45994, 51668, 58898, 81429, 86117, 86565) AND t.id < 1077783;