SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND n.surname_pcode LIKE '%3%' AND k.keyword = 'reference-to-taurus-the-constellation' AND n.id < 3775309 AND k.phonetic_code IS NOT NULL AND n.name_pcode_nf < 'Z4134';