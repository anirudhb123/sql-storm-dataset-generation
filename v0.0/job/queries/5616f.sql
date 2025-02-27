SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND ci.role_id IN (1, 11, 2, 3, 4, 6, 7, 8, 9) AND t.episode_nr IN (11451, 15454, 15686, 1677, 3230, 4049, 6893, 692, 8532, 9966) AND ci.person_id < 3487008 AND n.surname_pcode > 'D16' AND n.id > 1105546 AND ci.note IS NOT NULL;