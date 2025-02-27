SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.series_years > '1956-1990' AND k.keyword > 'kicking-in-a-window' AND mk.movie_id < 912016 AND t.production_year IS NOT NULL;