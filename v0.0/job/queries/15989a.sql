SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND ci.nr_order IN (1049, 22003, 302, 404, 422, 454) AND n.id > 199849 AND mk.id < 3773840 AND t.production_year > 1972 AND cn.name_pcode_sf IS NOT NULL;