SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND n.surname_pcode IN ('F261', 'J512', 'K246', 'O363', 'S436', 'S465', 'U21', 'V452', 'V541', 'V654') AND n.name_pcode_nf IS NOT NULL AND ci.note < '(as Freddie Howard)';