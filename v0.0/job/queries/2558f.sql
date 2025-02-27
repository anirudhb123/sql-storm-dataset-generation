SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND cn.md5sum < 'f282cab903e5e40f9bb7c7a7207d6d2a' AND n.name_pcode_cf IN ('B256', 'C1462', 'H2123', 'P6235', 'Q1564', 'Y1635', 'Z2532', 'Z6132');