SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.episode_of_id IS NOT NULL AND t.md5sum LIKE '%185%' AND t.season_nr IN (1, 11, 1987, 2007, 2012, 28, 6, 69, 7, 8) AND mi.movie_id < 1451340;