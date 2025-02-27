SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.id > 1570160 AND ci.nr_order < 820 AND t.title < 'Dozde bandar' AND n.name_pcode_cf IN ('E243', 'K124', 'M4162', 'M463', 'M5253', 'S4123', 'S4525', 'V2464', 'Z1212', 'Z35') AND n.surname_pcode > 'Z213';