SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.title > 'Bittere Mandeln' AND k.phonetic_code IN ('A2362', 'A3545', 'D5326', 'O2535', 'R2456', 'T3641', 'T5415', 'W6261', 'Y615');