SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.series_years IN ('1949-1998', '1959-1963', '1975-1989', '1983-1990', '1984-1988', '1985-1993', '1996-2004', '2008-2012');