SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND ci.note > '(secretary: Tony Bill)' AND n.id < 869303 AND k.keyword IN ('christmas-cracker', 'home-ownership', 'lung-removal', 'new-york-state-psychiatric-institute-168th-street-manhattan-new-york-city', 'reference-to-jennie-gerhardt', 'street-peddler', 'wedding-reception');