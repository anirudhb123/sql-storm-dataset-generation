SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND k.phonetic_code IS NOT NULL AND mk.keyword_id < 33115 AND t.season_nr IS NOT NULL AND t.md5sum > 'ae57376e77e46b9366dbce78a6835134' AND t.kind_id > 3 AND t.episode_nr > 1175;