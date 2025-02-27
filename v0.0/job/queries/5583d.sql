SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND ci.person_id > 333895 AND ci.movie_id < 2494955 AND ci.note IS NOT NULL AND n.imdb_index IS NOT NULL AND t.episode_of_id > 459844 AND ci.person_role_id < 1387810;