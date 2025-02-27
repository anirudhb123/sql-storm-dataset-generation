SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND k.keyword > 'dagenham-east-london' AND ci.role_id > 6 AND mk.keyword_id IN (11756, 129602, 19605, 22307, 32600, 62672, 64584, 74896, 7722, 96143);