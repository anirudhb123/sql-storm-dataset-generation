SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND ci.note IN ('(Cap-Head)', '(as Alberto Rodriguez)', '(as Bernard Gemahling)', '(as Earl Preston)', '(as Yda Yanesa)', '(motion capture designer: Visual Works: CG cinematics unit) (PlayStation 3 version)', '(script supervisor: second unit) (as Elizabeth Ludwick)');