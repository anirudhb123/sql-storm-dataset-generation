SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.country_code IS NOT NULL AND cn.md5sum < '3750f00fcae1113684ba8ae0a37902b9' AND t.production_year = 2006 AND mk.id > 1669529;