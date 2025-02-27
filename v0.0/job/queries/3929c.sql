SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND mk.id < 4065202 AND k.id < 109582 AND cn.md5sum > '1c9cc44278efc4e76d9dd2ccc09a3ef2' AND t.kind_id = 4 AND cn.country_code > '[je]';