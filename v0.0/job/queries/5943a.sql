SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.episode_of_id IS NOT NULL AND mk.keyword_id IN (100135, 47826, 51278, 79820, 80344, 91407, 96517) AND t.production_year > 1944 AND mi.id > 7528218;