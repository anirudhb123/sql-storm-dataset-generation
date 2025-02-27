SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND k.keyword < 'nothingness' AND k.id IN (108165, 132586, 13305, 21112, 3881, 41516) AND mc.note LIKE '%(TV)%' AND t.production_year < 1993;