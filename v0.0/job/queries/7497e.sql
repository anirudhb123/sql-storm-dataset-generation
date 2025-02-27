SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND k.keyword > 'struggling-author' AND t.series_years IN ('1953-2012', '1954-1974', '1966-1972', '1981-????', '1987-1999', '1993-1997', '1997-2007') AND n.name > 'Becker, Stephanus';