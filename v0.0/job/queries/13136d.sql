SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.name_pcode_sf < 'G2352' AND t.series_years IN ('1956-1974', '1970-1993', '1975-1996', '2006-2006') AND t.phonetic_code < 'M432';