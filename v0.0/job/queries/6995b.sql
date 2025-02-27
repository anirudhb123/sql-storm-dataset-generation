SELECT min(lt.link) AS link_type, min(t1.title) AS first_movie, min(t2.title) AS second_movie
FROM keyword AS k, link_type AS lt, movie_keyword AS mk, movie_link AS ml, title AS t1, title AS t2
WHERE mk.keyword_id = k.id AND t1.id = mk.movie_id AND ml.movie_id = t1.id AND ml.linked_movie_id = t2.id AND lt.id = ml.link_type_id AND mk.movie_id = t1.id
AND ml.link_type_id IN (11, 15, 17, 2, 3, 4, 5) AND lt.link IN ('featured in', 'follows', 'referenced in', 'references', 'remade as', 'remake of', 'spoofed in', 'unknown link', 'version of') AND t2.md5sum > 'f471eaefab8889590bcbba1f88635b36';