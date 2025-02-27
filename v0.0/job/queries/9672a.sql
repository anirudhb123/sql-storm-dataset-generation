SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.episode_nr IS NOT NULL AND t.episode_of_id IN (106190, 1069203, 1472065, 967245) AND mi.info < 'Portugal:10 April 2004' AND k.phonetic_code LIKE '%1%';