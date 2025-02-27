SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.imdb_index LIKE '%I%' AND t.md5sum IS NOT NULL AND cn.name_pcode_sf IN ('C412', 'E1414', 'I5251', 'J2425', 'K6423', 'M4641', 'S2346', 'Z42') AND k.phonetic_code IS NOT NULL AND mc.id < 2014983 AND cn.name_pcode_nf < 'Z6214';