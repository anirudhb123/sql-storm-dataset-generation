SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.series_years IN ('1935-1950', '1958-1959', '1966-1973', '1973-1981', '1997-2002', '2005-2011', '2006-2008') AND n.id < 3797784 AND t.md5sum < '8ab4b84df556fa8878575bc8648f9a81' AND ci.nr_order < 389;