SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND mc.company_id < 18325 AND t.id IN (1231629, 1771554, 206192, 2162378, 2338564, 2347295, 291354, 460255, 504367, 711477) AND mk.keyword_id > 8373 AND t.phonetic_code IS NOT NULL;