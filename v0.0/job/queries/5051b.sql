SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.phonetic_code > 'P3145' AND mc.id < 462479 AND mk.movie_id IN (1020629, 2348150) AND cn.name_pcode_sf IS NOT NULL AND t.episode_nr IS NOT NULL;