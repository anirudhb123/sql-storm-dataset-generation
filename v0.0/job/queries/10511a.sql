SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND cn.name_pcode_nf < 'F5142' AND ci.nr_order IN (103, 1036, 164, 1984, 3000, 505, 995) AND n.name_pcode_cf IS NOT NULL AND t.md5sum LIKE '%8d0%' AND k.id > 71210;