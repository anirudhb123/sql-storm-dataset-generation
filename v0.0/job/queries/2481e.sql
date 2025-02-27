SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.imdb_index = 'VIII' AND n.name_pcode_cf > 'K6465' AND t.phonetic_code < 'K6362' AND n.md5sum > '3beb2bcb8bd698c9965e7ec96bad3018' AND ci.role_id < 3;