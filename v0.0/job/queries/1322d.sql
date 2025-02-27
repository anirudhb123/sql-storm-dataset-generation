SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.episode_of_id IS NOT NULL AND t.production_year IN (1893, 1904, 1912, 1921, 1965, 1972, 1982, 2008, 2009, 2015);