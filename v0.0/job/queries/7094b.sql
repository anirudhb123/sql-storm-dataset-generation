SELECT min(lt.link) AS link_type, min(t1.title) AS first_movie, min(t2.title) AS second_movie
FROM keyword AS k, link_type AS lt, movie_keyword AS mk, movie_link AS ml, title AS t1, title AS t2
WHERE mk.keyword_id = k.id AND t1.id = mk.movie_id AND ml.movie_id = t1.id AND ml.linked_movie_id = t2.id AND lt.id = ml.link_type_id AND mk.movie_id = t1.id
AND ml.linked_movie_id > 1587848 AND t2.title LIKE '%Das%' AND t2.kind_id IN (6) AND t1.md5sum < 'f8e583661edd46b6b121d50cdb6216f9' AND k.phonetic_code IS NOT NULL;