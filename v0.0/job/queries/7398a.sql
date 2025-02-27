SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND ci.note IS NOT NULL AND ci.role_id IN (5, 7, 8) AND ci.nr_order = 1197 AND n.imdb_index LIKE '%I%' AND k.phonetic_code < 'F2161' AND n.md5sum < '2326e28c9ae90d12e1158247379a8ca6';