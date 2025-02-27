SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.title < 'Chasing Zero: Winning the War on Healthcare Harm' AND mc.company_id IN (101904, 113215, 1208, 175230, 189312, 20388, 224855, 226430, 59219, 85701) AND cn.md5sum IS NOT NULL;