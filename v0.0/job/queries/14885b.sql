SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND mc.note < '(2009) (Qatar) (all media)' AND t.phonetic_code < 'Z315' AND t.production_year IN (1916, 1931, 1943, 1958, 1963, 1980, 1985, 1994, 2007, 2016);