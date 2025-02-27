SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND it.info IN ('LD certification', 'LD official retail price', 'LD quality of source', 'LD quality program', 'LD sound encoding', 'LD status of availablility', 'LD subtitles', 'alternate versions', 'bottom 10 rank') AND k.phonetic_code < 'E1615';