SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND cn.name_pcode_sf IS NOT NULL AND n.md5sum > '2257560b920c6160545caad34535e020' AND cn.md5sum > 'cfa5650cef085c46b27577d0aad498a2' AND mc.movie_id IN (2045994, 492094);