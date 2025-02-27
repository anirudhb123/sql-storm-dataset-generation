SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND n.name_pcode_cf > 'B5164' AND k.id IN (100531, 106658, 10948, 133443, 13554, 32608, 4750, 52384, 81775) AND ci.person_role_id IS NOT NULL AND t.episode_of_id < 552579 AND t.phonetic_code > 'R3645' AND n.name_pcode_nf < 'Q2143';