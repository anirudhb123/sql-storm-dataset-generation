SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.imdb_index IN ('II', 'IV', 'X', 'XI', 'XIII', 'XVI', 'XVII', 'XVIII') AND t.series_years IN ('1941-1943', '1982-2003', '1984-1994', '1992-????');