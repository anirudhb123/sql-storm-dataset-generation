SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND n.name LIKE '%Labrosse,%' AND k.phonetic_code > 'S3153' AND n.surname_pcode > 'A212' AND t.md5sum < 'fd4601471a1499d0be2311c97f28836f';