SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.id IN (1254376, 16259, 2261223, 2311710, 2473365) AND t.production_year > 1931 AND cn.country_code IN ('[af]', '[br]', '[tw]');