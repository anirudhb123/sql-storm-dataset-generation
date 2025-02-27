SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND k.keyword > 'clinton-tennessee' AND mk.keyword_id IN (116729, 122396, 124421, 35982, 46067, 48542, 53868, 56342, 83077, 96624) AND n.imdb_index > 'XXIX';