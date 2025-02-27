SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.production_year > 1949 AND mc.company_id < 43100 AND t.phonetic_code > 'R341' AND k.phonetic_code IS NOT NULL AND t.id < 1368604 AND mc.id < 1968029;