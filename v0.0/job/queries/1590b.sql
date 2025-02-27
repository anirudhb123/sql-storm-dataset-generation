SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND ci.role_id IN (1, 10, 2, 3, 4, 6, 7, 9) AND mk.movie_id < 1960598 AND mk.id < 2029313 AND t.phonetic_code > 'R6436' AND mk.keyword_id < 46190 AND t.production_year < 1974 AND n.imdb_index < 'XXIX';