SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND k.keyword > 'radiation-induced-cancer' AND cn.name_pcode_sf IN ('B4353', 'D2162', 'F5256', 'I3213', 'N353', 'V1641', 'V3616', 'W1523') AND mk.keyword_id > 13821;