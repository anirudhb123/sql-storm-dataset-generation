SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.md5sum > '2f255672b3b5563bc9dfba0da7e2af1a' AND ci.role_id > 8 AND t.phonetic_code > 'I6124' AND t.imdb_index < 'XII';