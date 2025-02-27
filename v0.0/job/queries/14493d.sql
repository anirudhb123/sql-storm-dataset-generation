SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND ci.note IS NOT NULL AND k.phonetic_code IS NOT NULL AND k.keyword > 'thrown-into-a-swimming-pool' AND n.surname_pcode < 'K323' AND t.title LIKE '%No.%' AND n.name_pcode_nf LIKE '%3%';