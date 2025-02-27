SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND ci.movie_id > 2474138 AND t.production_year < 1984 AND n.name < 'Shigeno, Kenichiro' AND mk.movie_id > 859726 AND t.phonetic_code IN ('A3654', 'B646', 'E6252', 'F5431', 'L5121', 'M1436', 'P5452', 'Z2143');