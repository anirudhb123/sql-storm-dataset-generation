SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.phonetic_code IN ('B4645', 'I5321', 'P1351', 'Q4232') AND t.production_year IN (1893, 1943, 1950, 1985, 1992, 1998, 2003, 2019);