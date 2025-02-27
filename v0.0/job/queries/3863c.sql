SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.md5sum > 'ca027dc68b1068eeebd226ccc6a5f7bf' AND t.series_years IN ('1963-1990', '1964-1999', '1965-1986', '1971-1977', '2002-2003');