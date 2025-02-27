SELECT min(lt.link) AS link_type, min(t1.title) AS first_movie, min(t2.title) AS second_movie
FROM keyword AS k, link_type AS lt, movie_keyword AS mk, movie_link AS ml, title AS t1, title AS t2
WHERE mk.keyword_id = k.id AND t1.id = mk.movie_id AND ml.movie_id = t1.id AND ml.linked_movie_id = t2.id AND lt.id = ml.link_type_id AND mk.movie_id = t1.id
AND t1.series_years LIKE '%1966%' AND t2.phonetic_code > 'Q245' AND mk.keyword_id < 36368 AND k.id < 11059 AND t2.kind_id IN (0, 1, 2, 3, 4, 6, 7);