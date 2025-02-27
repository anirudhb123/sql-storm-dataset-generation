SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND k.phonetic_code > 'G6356' AND t.md5sum IN ('007a5cbaa02721645590a0d9a20f478b', '74fa6e33f587319aadb5eab87cbf9668', '78cf81298dc2aede6c9de012513ae37e') AND k.id < 64311;