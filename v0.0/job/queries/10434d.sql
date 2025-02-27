SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.phonetic_code IN ('A3616', 'C3635', 'E35', 'F4563', 'G634', 'H6465', 'K616', 'N6232', 'W5342') AND n.name_pcode_nf IN ('H6562', 'L1525', 'O5242');