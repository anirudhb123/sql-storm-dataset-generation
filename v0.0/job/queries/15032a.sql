SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND ci.nr_order IS NOT NULL AND n.name_pcode_cf IN ('A6231', 'D5251', 'G6146', 'M5156', 'T6232', 'Z2513', 'Z3153', 'Z4314') AND t.kind_id IN (6, 7) AND mc.id > 1735739;