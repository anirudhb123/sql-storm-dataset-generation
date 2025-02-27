SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND n.md5sum < 'fd29ae71d87c62d31fa0d5f75ef0ce5e' AND ci.person_role_id IN (1390751, 1673360, 2001030, 2424962, 2478811, 2565683, 2904366);