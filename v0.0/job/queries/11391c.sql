SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND ci.nr_order < 130 AND t.series_years IN ('1697-1764', '1936-1952', '1951-1971', '1961-1966', '1961-1973', '1964-1971', '1966-1986', '1977-2003', '2008-2009');