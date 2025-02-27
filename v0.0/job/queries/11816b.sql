SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.md5sum < 'b87a830f2344dfc38f6c31ac130a4913' AND mk.id > 1934304 AND k.phonetic_code = 'A5352' AND cn.name_pcode_nf < 'L3561';