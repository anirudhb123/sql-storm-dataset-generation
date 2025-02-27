SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND n.gender LIKE '%f%' AND ci.nr_order < 7004 AND mk.keyword_id IN (123258, 129903, 33618, 47721, 57090, 65083, 76199, 78) AND t.kind_id > 3;