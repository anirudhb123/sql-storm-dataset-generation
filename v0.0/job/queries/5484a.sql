SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.kind_id > 0 AND mk.id IN (2472836, 2616851, 2735039, 3119847, 3298387, 3368925, 4143582, 552168, 956539);