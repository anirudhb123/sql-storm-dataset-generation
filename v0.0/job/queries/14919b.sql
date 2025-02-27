SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mk.keyword_id > 27974 AND t.season_nr IN (10, 12, 2, 38, 49, 56, 58, 6, 63, 65) AND t.episode_of_id IS NOT NULL AND t.production_year IN (1916, 1922, 1936, 1967, 1973, 1979) AND t.episode_nr IS NOT NULL;