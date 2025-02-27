SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND k.phonetic_code < 'I6235' AND n.md5sum < 'e2149abf762339b2db6ff9fcaee51ae8' AND n.imdb_index < 'LXI' AND t.phonetic_code IN ('G3146', 'L5351', 'M3562', 'T5635');