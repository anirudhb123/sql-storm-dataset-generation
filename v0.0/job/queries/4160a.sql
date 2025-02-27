SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.name < 'Screen 7 Jam' AND k.keyword > 'software-bug' AND t.episode_of_id IS NOT NULL AND cn.name_pcode_sf < 'H5356' AND mc.company_type_id = 1;