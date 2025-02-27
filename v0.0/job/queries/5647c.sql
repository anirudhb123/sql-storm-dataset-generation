SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND mk.id > 494579 AND mi_idx.info > '2.1..11.11' AND t.series_years IN ('1962-1970', '1965-1979', '1973-1992', '1984-1984', '1987-1998', '1997-1998', '2001-2012', '2012-2012');