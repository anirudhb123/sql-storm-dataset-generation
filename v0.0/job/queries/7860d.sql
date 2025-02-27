SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND n.name_pcode_cf IN ('A1265', 'B6165', 'J263', 'N4264', 'P2645', 'Q4526', 'V4212') AND t.imdb_index IS NOT NULL AND t.title < 'Brian Pillman: Loose Cannon';