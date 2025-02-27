SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND ci.role_id IN (1, 10, 11, 2, 3, 5, 6, 7) AND t.md5sum < 'caa1d3a0a38ef78d730fe0b717d72a24' AND t.kind_id = 2 AND n.imdb_index > 'LXVIII' AND ci.person_role_id IS NOT NULL;