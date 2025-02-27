SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND mk.movie_id IN (168011, 1916162, 2031316, 2041177, 2288763, 2445365) AND n.id < 4084137 AND n.name_pcode_cf IS NOT NULL AND t.season_nr IS NOT NULL AND n.name < 'Maxwell, Jaden';