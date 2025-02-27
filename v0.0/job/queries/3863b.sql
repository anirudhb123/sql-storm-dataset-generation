SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND mc.company_type_id < 2 AND mk.keyword_id = 5256 AND cn.md5sum < 'daa5e2465d5b5fc4b7161690668f3b6f';