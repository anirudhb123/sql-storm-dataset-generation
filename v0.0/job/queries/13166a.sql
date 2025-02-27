SELECT min(lt.link) AS link_type, min(t1.title) AS first_movie, min(t2.title) AS second_movie
FROM keyword AS k, link_type AS lt, movie_keyword AS mk, movie_link AS ml, title AS t1, title AS t2
WHERE mk.keyword_id = k.id AND t1.id = mk.movie_id AND ml.movie_id = t1.id AND ml.linked_movie_id = t2.id AND lt.id = ml.link_type_id AND mk.movie_id = t1.id
AND k.phonetic_code IN ('G235', 'I62', 'K3213', 'M43', 'P5253', 'R1312', 'W1245', 'W534', 'Y6262') AND k.keyword < 'rogallo' AND t2.md5sum IS NOT NULL;