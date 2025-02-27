SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND n.name_pcode_nf < 'Y2654' AND ci.role_id = 6 AND n.imdb_index < 'XXXIV' AND ci.note < '(as Sal Richichi)' AND ci.person_id > 652750 AND t.phonetic_code IS NOT NULL;