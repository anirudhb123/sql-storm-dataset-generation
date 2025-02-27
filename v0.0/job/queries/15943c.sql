SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND t.kind_id IN (2, 3, 7) AND it.info > 'LD status of availablility' AND t.series_years IN ('1938-1999', '1947-1954', '1962-1963', '1968-1976', '1969-1969', '2005-2007') AND mi_idx.id < 1175698;