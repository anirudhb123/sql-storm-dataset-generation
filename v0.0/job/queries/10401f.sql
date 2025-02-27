SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND k.id < 39641 AND mk.id > 1426185 AND ci.note IN ('(as Arthur Winkler)', '(as W.T. Carlton)', '(caterer: Michaelson Food Services) (as Benny Padilla)', '(executive producer: TV2 Zulu) (2003-2004)', '(production coordinator) (as Roger P. Carr)', '(segment "Vandi Verma") (uncredited)');