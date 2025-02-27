SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.series_years < '1973-1978' AND t.production_year IN (1958, 1959) AND t.imdb_index LIKE '%I%' AND cn.name_pcode_sf IS NOT NULL AND t.phonetic_code < 'Q4512' AND cn.country_code > '[as]' AND mk.movie_id < 1839678 AND mc.note < '(2001-2004) (USA) (TV) (original airing)';