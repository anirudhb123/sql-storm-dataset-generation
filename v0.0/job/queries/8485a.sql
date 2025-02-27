SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND t.series_years IN ('1955-1961', '1968-1969', '1980-2000', '1983-1992', '1991-1997', '1994-2002', '2003-????') AND k.keyword > 'reference-to-ed-sullivan' AND mk.keyword_id < 42537;