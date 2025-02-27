SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND t.series_years IN ('1936-1938', '1971-1988', '1974-1984', '1976-1976', '1982-1993', '1985-1999', '1991-1991', '????') AND t.title < 'Stevie Nicks Goes Glee' AND mi_idx.info < '5..0010...';