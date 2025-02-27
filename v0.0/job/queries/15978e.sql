SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND k.keyword > 'anorexia' AND n.name > 'François, France' AND n.surname_pcode IN ('C143', 'E631', 'G64', 'H6', 'N61', 'N646', 'R246', 'S512', 'T212') AND t.imdb_index IN ('I', 'IV', 'IX', 'VII', 'VIII', 'XV', 'XVII', 'XXIII');