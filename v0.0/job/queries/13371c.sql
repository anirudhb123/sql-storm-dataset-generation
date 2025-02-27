SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.kind_id IN (1, 2, 3, 4, 6, 7) AND n.name_pcode_cf < 'S4546' AND n.imdb_index > 'LXIV' AND n.md5sum < 'b7153bc5818eb22bfaffb522db8a8cb2' AND ci.note < '(office assistant) (as Shekhar)' AND k.id < 99389 AND n.name > 'Granger, William';