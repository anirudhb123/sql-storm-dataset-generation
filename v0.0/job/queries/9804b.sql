SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.episode_of_id > 1227488 AND mi.info < 'La Défense, Hauts-de-Seine, France' AND t.md5sum < '2136bd16ee15eb3c749c7ecfbad6e59e';