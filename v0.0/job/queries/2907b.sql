SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.series_years IN ('1898-1918', '1952-1970', '1957-1964', '1965-1986', '1971-1981', '1975-1982', '1977-????', '1986-2010', '1998-1998', '2006-2013');