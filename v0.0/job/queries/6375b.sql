SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND n.id < 636729 AND t.series_years IN ('1955-????', '1957-1958', '1959-1963', '1962-1966', '1972-1980', '1974-1977', '1974-1979', '1977-1978', '1995-2000', '1996-????');