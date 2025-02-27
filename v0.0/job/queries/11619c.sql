SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.series_years IN ('1936-1952', '1962-1964', '1970-1988', '1972-1992', '1981-1990', '1981-1995', '1984-2009', '2006-2012');