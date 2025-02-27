SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND n.name_pcode_nf < 'S154' AND ci.movie_id < 1951668 AND ci.id < 12873145 AND k.phonetic_code LIKE '%53%' AND n.name_pcode_cf > 'A2614' AND t.production_year = 1935;