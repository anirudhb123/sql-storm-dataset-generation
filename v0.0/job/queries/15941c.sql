SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.id > 1384237 AND t.imdb_index LIKE '%I%' AND t.production_year > 1888 AND cn.name_pcode_nf IN ('H6525', 'Y5124');