SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND mi_idx.id < 961435 AND t.series_years IN ('1929-1941', '1958-1979', '1974-2013', '1975-1992', '1977-1989', '1980-2003', '1981-1990', '1984-1991', '1995-2003', '2001-2003');