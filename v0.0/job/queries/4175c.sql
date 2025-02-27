SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND n.surname_pcode < 'Y256' AND n.name_pcode_nf < 'P4636' AND n.name_pcode_cf IN ('A5353', 'F1465', 'I3154', 'I6326', 'N2434', 'O3214', 'P341', 'S3625', 'U413');