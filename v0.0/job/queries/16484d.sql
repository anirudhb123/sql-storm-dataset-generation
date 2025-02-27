SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND t.kind_id > 3 AND cn.md5sum < 'c2c2e1860cab5678b52635e46cec2b07' AND ci.role_id IN (3, 5, 9) AND mk.keyword_id > 6350 AND t.imdb_index < 'XXII';