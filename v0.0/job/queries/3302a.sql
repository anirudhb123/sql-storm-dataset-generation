SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.title < 'Seann Scott: Monk-y Business' AND mc.note LIKE '%(Canada)%' AND t.production_year IN (1899, 1901, 1925, 1946, 1990, 1994);