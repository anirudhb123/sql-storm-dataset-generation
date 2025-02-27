SELECT min(lt.link) AS link_type, min(t1.title) AS first_movie, min(t2.title) AS second_movie
FROM keyword AS k, link_type AS lt, movie_keyword AS mk, movie_link AS ml, title AS t1, title AS t2
WHERE mk.keyword_id = k.id AND t1.id = mk.movie_id AND ml.movie_id = t1.id AND ml.linked_movie_id = t2.id AND lt.id = ml.link_type_id AND mk.movie_id = t1.id
AND t1.episode_of_id < 994451 AND k.phonetic_code IN ('B4231', 'C1414', 'C5153', 'L1324', 'L2452', 'O625', 'P2324', 'P5324', 'R6421', 'T5321');