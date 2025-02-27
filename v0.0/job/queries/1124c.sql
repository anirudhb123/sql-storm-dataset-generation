SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND mc.company_type_id > 1 AND mk.movie_id IN (1828882, 1911322, 2001792, 2119372, 2155025, 2216332, 2470093, 757664, 793359);