SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND n.id > 2188767 AND t.md5sum < 'ebef876762e8717df084b6ff2f08f8a0' AND k.keyword IN ('car-radiator', 'double-engagement', 'new-age-movement', 'twenty-years-ago') AND mc.id < 1115439;