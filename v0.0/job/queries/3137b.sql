SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.name_pcode_nf IS NOT NULL AND t.production_year < 1939 AND cn.md5sum IS NOT NULL AND t.imdb_index IS NOT NULL AND t.md5sum LIKE '%4ed%' AND t.phonetic_code < 'R1534';