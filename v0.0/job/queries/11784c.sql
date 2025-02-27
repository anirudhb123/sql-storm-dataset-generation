SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.imdb_index IS NOT NULL AND k.phonetic_code > 'Z4142' AND t.production_year IN (1896, 1910, 1920, 1932, 1934, 1935, 1974, 1987, 2010, 2011);