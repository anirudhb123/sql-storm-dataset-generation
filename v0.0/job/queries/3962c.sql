SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND k.keyword < 'pioneer-theatre' AND t.production_year IS NOT NULL AND t.season_nr IN (10, 102, 2013, 25, 54, 70) AND t.phonetic_code IS NOT NULL;