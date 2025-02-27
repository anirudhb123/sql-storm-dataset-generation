SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.md5sum IS NOT NULL AND mc.movie_id IN (1237286, 1376531, 1395323, 1400006, 1443776, 1671270, 2119929, 2271887, 303745, 570968);