SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mk.id IN (2182210, 2614232, 2808376, 3065905, 3540920, 3557584, 630340, 858967) AND t.episode_nr IS NOT NULL;