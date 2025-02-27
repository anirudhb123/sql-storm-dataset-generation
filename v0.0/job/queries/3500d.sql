SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.series_years IN ('1949-1951', '1957-1963', '1971-1997', '1980-1985', '1990-1996', '2008-2009') AND mc.note < '(2010) (UK) (theatrical) (3-D version)' AND cn.md5sum IS NOT NULL;