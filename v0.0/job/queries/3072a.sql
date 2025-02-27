SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.title > 'Horse Sense and Soldiers' AND t.md5sum LIKE '%3b4c%' AND t.episode_of_id < 1518799;