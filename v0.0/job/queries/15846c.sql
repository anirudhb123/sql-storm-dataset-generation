SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.md5sum LIKE '%80%' AND t.imdb_index IS NOT NULL AND ci.role_id IN (1, 10, 11, 3, 8, 9) AND mk.keyword_id > 58092 AND ci.note < '(key assistant location manager) (as Pamela D.Pella)';