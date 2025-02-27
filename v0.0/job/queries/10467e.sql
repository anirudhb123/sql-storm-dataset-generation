SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND n.gender IN ('m') AND ci.nr_order IN (103, 1039, 1090, 1102, 158, 20041214, 306, 3300, 429, 67173578) AND k.keyword < 'indian-maiden';