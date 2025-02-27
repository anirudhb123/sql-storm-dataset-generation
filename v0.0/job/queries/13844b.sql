SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND n.name_pcode_nf = 'T3526' AND cn.md5sum LIKE '%b%' AND mc.company_id < 77789 AND n.imdb_index > 'CXCII' AND ci.role_id = 8 AND n.gender IN ('f', 'm');