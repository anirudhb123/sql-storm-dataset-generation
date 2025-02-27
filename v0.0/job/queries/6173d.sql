SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.name_pcode_sf < 'K6321' AND t.production_year = 1924 AND cn.id > 177249 AND mk.keyword_id < 43053 AND mc.company_type_id > 1 AND k.id < 96874;