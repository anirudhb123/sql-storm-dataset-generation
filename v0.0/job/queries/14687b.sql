SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.production_year IS NOT NULL AND t.series_years IN ('1950-1960', '1954-1959', '1962-1964', '1964-1985', '1964-1986', '1965-1970', '1971-1976', '1984-1987') AND cn.name_pcode_sf > 'K2153' AND mc.note < '(presents) (as Universal) (A Joe Pasternak Production)';