SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND n.md5sum LIKE '%ba%' AND ci.person_role_id < 2018618 AND t.episode_nr IN (11217, 13247, 1966, 5991, 6812, 7273, 81, 8110, 8361) AND t.production_year > 1987 AND n.gender IN ('m') AND mk.movie_id > 1414837;