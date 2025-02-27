SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.id < 796401 AND t.production_year IN (1891, 1919, 1921, 1946, 1956, 1971, 1972, 1996, 2006);