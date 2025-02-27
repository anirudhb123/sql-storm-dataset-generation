SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.md5sum > '3cb94a9988776d3289e0519b33ae6d76' AND mk.movie_id IN (1141079, 1283587, 1662702, 1788365, 1952427, 2070004, 2093097, 2395058, 842194);