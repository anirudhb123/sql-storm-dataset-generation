SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND mc.id IN (1077802, 1326829, 1458952, 1578660) AND t.phonetic_code IS NOT NULL AND k.phonetic_code IS NOT NULL AND t.production_year IS NOT NULL;