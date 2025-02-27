SELECT min(lt.link) AS link_type, min(t1.title) AS first_movie, min(t2.title) AS second_movie
FROM keyword AS k, link_type AS lt, movie_keyword AS mk, movie_link AS ml, title AS t1, title AS t2
WHERE mk.keyword_id = k.id AND t1.id = mk.movie_id AND ml.movie_id = t1.id AND ml.linked_movie_id = t2.id AND lt.id = ml.link_type_id AND mk.movie_id = t1.id
AND t1.kind_id > 3 AND ml.link_type_id IN (17, 4, 5, 8) AND t2.kind_id < 2 AND ml.movie_id > 144286 AND t2.md5sum IS NOT NULL AND t1.phonetic_code IS NOT NULL;