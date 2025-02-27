SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.imdb_index IS NOT NULL AND mc.id < 2141956 AND t.md5sum LIKE '%bb%' AND mc.company_id < 45623 AND cn.name_pcode_nf IN ('M1314', 'S5163', 'T4252');