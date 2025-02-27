SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.name_pcode_sf LIKE '%5%' AND cn.name_pcode_nf IS NOT NULL AND t.imdb_index LIKE '%V%' AND t.phonetic_code IS NOT NULL AND cn.id < 43641;