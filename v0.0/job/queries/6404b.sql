SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.id > 622514 AND mk.keyword_id IN (118776, 121061, 15670, 20138, 2093, 38101, 40595, 40645, 88111) AND mc.movie_id > 1727129;