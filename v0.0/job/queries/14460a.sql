SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND ci.movie_id < 2256740 AND n.md5sum > '5a01c1757c4c7d3033880c648117faa5' AND ci.person_role_id IS NOT NULL AND t.kind_id IN (0, 1, 2, 4, 6, 7) AND t.phonetic_code < 'X5143';