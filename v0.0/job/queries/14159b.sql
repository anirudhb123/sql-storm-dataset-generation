SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.name_pcode_nf IS NOT NULL AND cn.md5sum < '7136f01d2d038ed0127fd142e66c1c1f' AND t.production_year < 1937 AND t.kind_id IN (0, 1, 2, 3, 6, 7);