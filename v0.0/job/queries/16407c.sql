SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND n.name_pcode_nf < 'B5245' AND k.phonetic_code IN ('A5124', 'F3124', 'F3613', 'P2343', 'R154', 'R2165', 'V5342', 'W5264') AND t.title > '1.8,9,10,11,12' AND t.md5sum LIKE '%6%' AND n.md5sum LIKE '%f3%';