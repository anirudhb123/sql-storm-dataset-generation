SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.md5sum < 'f84d2e3241ef394a7a326e3f4e1071bd' AND ci.role_id IN (2, 9) AND ci.movie_id > 1298980 AND k.keyword < 'miss-canada';