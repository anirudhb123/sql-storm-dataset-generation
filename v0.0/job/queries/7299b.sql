SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND ci.note IN ('(as Charles T. Baxter)', '(as Chip Esten)', '(as Pamela L. Incardona)', '(segment "Glauben und Gestehen")', '(segment "Uganda Be An Elephant")');