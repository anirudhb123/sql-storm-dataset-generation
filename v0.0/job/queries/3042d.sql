SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.imdb_index LIKE '%II%' AND n.md5sum > '88dd4b7d93f3813a09107372f204babe' AND ci.person_role_id IS NOT NULL AND k.keyword < 'show-room' AND t.md5sum < 'cc216da2abab5a876646a99fb7d9e2bc';