SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND mk.movie_id < 542575 AND mc.note IS NOT NULL AND t.production_year < 1998 AND k.keyword > 'artificial-tear' AND k.phonetic_code IN ('A5451', 'I3525', 'S1643', 'S3631', 'W4156');