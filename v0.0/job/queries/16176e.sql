SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND n.md5sum < '6803583016f95766be92c6e1a96f0581' AND n.imdb_index > 'XXXVI' AND t.production_year = 1981 AND n.id < 1735601 AND k.phonetic_code IS NOT NULL;