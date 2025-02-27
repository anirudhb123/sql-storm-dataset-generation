SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND ci.person_role_id IN (1310433, 1598602, 1671815, 2218932, 2879895, 3068121, 368025, 757093, 932441) AND mc.id > 2126297 AND cn.md5sum < 'df2b0a5b967e2b35ea528434f63da6bf';