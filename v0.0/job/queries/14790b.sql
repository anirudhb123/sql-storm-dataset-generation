SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND n.gender IS NOT NULL AND ci.person_id > 2042483 AND ci.nr_order IS NOT NULL AND t.episode_nr IS NOT NULL AND n.imdb_index LIKE '%I%' AND k.phonetic_code > 'I216';