SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.series_years IN ('1932-1938', '1948-1953', '1949-1961', '1952-1953', '1965-1999', '1974-1978', '1979-1979');