SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.imdb_index IS NOT NULL AND ci.id > 2779190 AND n.imdb_index IS NOT NULL AND k.keyword = 'loss-of-sanity' AND t.kind_id < 7 AND t.md5sum IS NOT NULL;