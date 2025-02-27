SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.series_years IN ('1957-1979', '1962-1993', '1963-1964', '1970-1971', '1978-1990', '1986-2004', '1987-2005', '1994-2007', '2006-2009', '2011-2013');