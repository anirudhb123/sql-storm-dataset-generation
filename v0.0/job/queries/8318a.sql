SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND k.id > 61005 AND t.phonetic_code IN ('E525', 'F5352', 'H6231', 'Q2623', 'S3634', 'X1436', 'Y1426') AND cn.name_pcode_nf LIKE '%41%' AND t.title > 'Lost and Found in Space';