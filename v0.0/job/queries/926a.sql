SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.name < 'Spirit EMX' AND t.production_year IN (1916, 2008) AND t.season_nr IS NOT NULL AND k.keyword < 'spurting-blood' AND cn.md5sum > 'dfc0c15bb3b184ae44b08f3a754b3126';