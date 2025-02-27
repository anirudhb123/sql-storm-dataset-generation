SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND k.phonetic_code IN ('A5123', 'C612', 'E2532', 'J2364', 'L2465', 'M4256', 'W6526') AND t.phonetic_code > 'O264' AND t.production_year < 2005 AND t.id < 2438978 AND t.episode_of_id < 1475568;