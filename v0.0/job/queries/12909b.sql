SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND ci.person_role_id > 768204 AND n.surname_pcode IN ('E613', 'F426', 'H14', 'H352', 'R124', 'S63', 'V314', 'Y323') AND n.name_pcode_nf IS NOT NULL AND t.id < 2052408;