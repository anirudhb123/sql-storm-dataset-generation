SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND mc.company_type_id IN (1, 2) AND cn.md5sum > 'd7ebd4ac5c19b35816051fda4f324e3e' AND ci.nr_order > 1109 AND k.id IN (100564, 105876, 117388, 125868, 32897, 46035, 46988, 92904);