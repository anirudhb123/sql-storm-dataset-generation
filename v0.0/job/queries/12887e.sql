SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND cn.name_pcode_nf IS NOT NULL AND ci.role_id IN (10, 11, 2) AND cn.md5sum < '52899b71d52b41be674e20bd74363f5e' AND mk.keyword_id < 40509 AND n.name_pcode_cf IN ('A1632');