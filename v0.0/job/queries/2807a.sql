SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND mc.note IS NOT NULL AND t.phonetic_code = 'R5436' AND t.md5sum > '206d0a80bc3816023c67f2ee96f0063f' AND t.id < 808959 AND cn.name_pcode_nf < 'O5452';