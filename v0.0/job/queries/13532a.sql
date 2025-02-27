SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.md5sum IS NOT NULL AND cn.name IN ('Centro Cultural Alfa', 'Darkest Fear Films') AND cn.name_pcode_nf LIKE '%2%' AND cn.id < 225263;