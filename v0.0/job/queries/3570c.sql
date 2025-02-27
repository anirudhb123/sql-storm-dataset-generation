SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND n.surname_pcode IS NOT NULL AND t.episode_nr < 2898 AND mk.keyword_id IN (10133, 25629, 32063, 42131, 43901, 56252, 71476, 86927, 90906, 91859);