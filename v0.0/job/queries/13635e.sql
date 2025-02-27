SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.series_years > '1973-1973' AND ci.nr_order < 831 AND t.kind_id > 0 AND ci.role_id IN (11, 2, 3, 5, 9) AND n.name_pcode_nf LIKE '%42%';