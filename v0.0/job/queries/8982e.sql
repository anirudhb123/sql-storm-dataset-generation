SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND ci.person_role_id < 2121406 AND t.series_years IN ('1941-????', '1957-1968', '1958-1960', '1972-1983', '1976-1985', '1979-????', '1984-????', '1986-1997', '1993-2006', '1994-2008') AND ci.role_id IN (1, 10, 11, 4, 6, 8, 9) AND ci.person_id < 3536565 AND n.surname_pcode IS NOT NULL;