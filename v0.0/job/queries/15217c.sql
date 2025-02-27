SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND k.phonetic_code > 'J264' AND t.kind_id > 1 AND t.season_nr IN (2006, 21, 30, 34, 37, 39, 51, 6, 69, 91) AND mi_idx.movie_id < 2399929 AND t.id < 1133252 AND t.production_year IN (1901, 1902, 1919, 1931, 1968, 1978, 1988, 1996);