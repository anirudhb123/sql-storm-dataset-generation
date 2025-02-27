SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.imdb_index IS NOT NULL AND ci.role_id IN (10, 3, 6, 7, 8, 9) AND k.id > 54743 AND ci.note < '(as Jesse Balboa)' AND ci.id < 34726119 AND n.name_pcode_cf IN ('F3453', 'M2424', 'P2362', 'S1546', 'V3212', 'V3415');