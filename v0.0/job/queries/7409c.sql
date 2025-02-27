SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND mc.id > 1725312 AND ci.note IS NOT NULL AND t.production_year IN (1891, 1902, 1946, 1950, 1968, 2004, 2006, 2008) AND n.name_pcode_nf IS NOT NULL AND n.surname_pcode < 'D326';