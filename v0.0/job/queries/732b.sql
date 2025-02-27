SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND n.surname_pcode > 'Q24' AND n.md5sum IS NOT NULL AND k.id IN (109041, 12562, 127854, 28640, 32715, 33597, 37029, 46460, 90163, 912) AND ci.movie_id < 770709;