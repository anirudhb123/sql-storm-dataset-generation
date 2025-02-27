SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND t.series_years IN ('1946-1950', '1948-1949', '1967-1985', '1969-1994', '1971-1984', '1973-1989', '1983-1988', '1991-2009', '1992-1995', '1999-2009');