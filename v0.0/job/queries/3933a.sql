SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND ci.person_role_id > 1706251 AND t.phonetic_code = 'F4126' AND n.name_pcode_cf LIKE '%5%' AND t.md5sum < '4dbffa767bbb6b7fd165d331ed7f4ce7' AND n.surname_pcode IS NOT NULL AND n.name_pcode_nf < 'H4534';