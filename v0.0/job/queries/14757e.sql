SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.episode_nr < 11385 AND n.imdb_index < 'LXXXVIII' AND ci.nr_order IN (1034, 12002, 1710, 2045, 24000, 340, 364, 612, 623893950, 830);