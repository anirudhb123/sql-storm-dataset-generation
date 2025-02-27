SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.kind_id IN (0, 1, 2, 3, 6, 7) AND n.name_pcode_cf < 'U4151' AND n.gender < 'm' AND n.surname_pcode IN ('B325', 'J141', 'J246', 'P642', 'T125', 'V362');