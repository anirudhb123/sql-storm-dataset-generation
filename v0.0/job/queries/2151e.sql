SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND ci.id > 33219095 AND ci.note < '(head of drama: Network Ten)' AND t.series_years IN ('1955-1987', '1971-1979', '1973-1985', '1980-2007', '1989-2013', '2012-????');