SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.episode_nr > 4450 AND n.gender = 'm' AND k.keyword < 'rube' AND n.imdb_index < 'XVI' AND t.phonetic_code LIKE '%2%' AND t.episode_of_id > 287697;