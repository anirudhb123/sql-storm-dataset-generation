SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND n.name_pcode_nf LIKE '%2%' AND k.id < 81119 AND t.md5sum > '9c05b1d33f1f78e9ca4a15efb377b506' AND ci.note IN ('(Executive ABC Network)', '(archive footage) (as Masasa)', '(as Regina Gelfan)', '(as Santana S. Lorena)', '(novel "Bat out of Bell")', '(scenario) (as Per Lennart)');