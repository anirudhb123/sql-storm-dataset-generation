SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.title > 'La transformación es el camino' AND t.season_nr IN (1981, 1988, 1990, 1998, 2013, 27, 32, 55, 69, 70) AND n.name_pcode_cf IS NOT NULL AND t.episode_nr < 4318 AND ci.person_role_id > 54565;