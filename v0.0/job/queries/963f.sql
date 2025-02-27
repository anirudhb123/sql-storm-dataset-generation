SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND n.md5sum < '2b9e5462ce92bd71305b71981c41de35' AND k.phonetic_code IN ('C2524', 'F4562', 'J4631', 'M2632', 'P1325', 'P1362', 'S153', 'V6352');