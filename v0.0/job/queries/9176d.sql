SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.id < 90447 AND k.keyword > 'loss-of-nose' AND mc.company_id IN (107433, 108879, 159574, 182166, 36839, 4006, 45904, 65160, 81236);