SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND cn.name_pcode_nf IN ('J5134', 'K6', 'K6341', 'N1641', 'P1626', 'P2124', 'P3264', 'Q231', 'S3613', 'Y2421') AND n.md5sum > '13dc985e7a3fae03bf687ae73b4ac6d2';