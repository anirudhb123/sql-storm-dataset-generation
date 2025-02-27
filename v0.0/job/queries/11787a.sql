SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND ci.nr_order IS NOT NULL AND n.name_pcode_cf IS NOT NULL AND t.production_year > 1963 AND ci.person_id IN (1152099, 1995707, 2293834, 2360316, 3661345, 3755458, 588823, 842165, 972443, 985081) AND ci.id > 53915;