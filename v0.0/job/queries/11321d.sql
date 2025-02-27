SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND mc.movie_id IN (1450259, 1926473, 2090184, 2138853, 2188393, 2315484, 2381119, 553388, 556908, 800963) AND cn.md5sum IS NOT NULL;