SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.production_year IN (1920, 1941, 1942, 1963, 1964, 1965, 1988) AND mk.keyword_id IN (12169, 121895, 130939, 17503, 26338, 55435, 69604, 73929) AND mc.movie_id > 1992534;