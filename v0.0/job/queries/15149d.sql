SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.md5sum > '1d25c1115f12d43b898a0f7254d2efc9' AND t.md5sum IS NOT NULL AND cn.country_code IS NOT NULL AND mk.id > 2670372;