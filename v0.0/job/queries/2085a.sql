SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND n.imdb_index > 'VI' AND ci.movie_id < 1379561 AND t.series_years IN ('1938-1999', '1950-1993', '1961-1966', '1964-1971', '1966-1974', '1978-????', '1990-2002', '2011-2012') AND t.md5sum < 'b02ce90b48773b0b6f2884170f425e5c';