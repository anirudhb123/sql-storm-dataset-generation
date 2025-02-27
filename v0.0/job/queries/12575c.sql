SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND mc.movie_id < 40957 AND cn.md5sum > 'c4a66c65d63a8770d931cc22bbe5b99f' AND mk.movie_id < 1379619 AND cn.name_pcode_sf LIKE '%43%';