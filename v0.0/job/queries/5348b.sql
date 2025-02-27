SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND mc.id > 1941376 AND t.kind_id > 2 AND t.id < 1864492 AND t.production_year IS NOT NULL AND cn.name_pcode_sf IS NOT NULL AND mk.keyword_id > 54693 AND mk.movie_id < 2378182 AND k.phonetic_code IS NOT NULL;