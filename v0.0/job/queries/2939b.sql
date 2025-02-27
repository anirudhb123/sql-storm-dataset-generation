SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND mc.company_id < 88743 AND cn.md5sum < 'dd9cd2c9cfb2be85f1425431d0d5a1b5' AND t.season_nr IS NOT NULL;