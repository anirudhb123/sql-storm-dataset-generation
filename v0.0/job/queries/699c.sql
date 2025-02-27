SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND n.gender IS NOT NULL AND mk.keyword_id = 3040 AND t.production_year IS NOT NULL AND mk.id < 4109862 AND ci.person_role_id < 1563611 AND t.series_years > '2001-2005';