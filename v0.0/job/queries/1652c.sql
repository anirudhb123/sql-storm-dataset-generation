SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND mc.note > '(2009) (Hungary) (TV) (season 1)' AND k.id = 9262 AND cn.md5sum > '0cc78c6efa12f71a1d78743fd0fb2ae4';