SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND k.phonetic_code < 'M2563' AND it.id > 12 AND t.series_years IN ('1955-1961', '1958-1996', '1968-????', '1971-2002', '1976-1986', '1985-1995', '1990-1994', '1995-2000', '2001-2001') AND t.title > 'Flesh for the Beast';