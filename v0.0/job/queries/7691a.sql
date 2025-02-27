SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.id IN (130843, 139514, 185067, 213282, 234522, 60227, 78444, 96784) AND mc.company_id < 81353 AND mk.keyword_id < 6494;