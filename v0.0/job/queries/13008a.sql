SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND ci.person_role_id > 152284 AND ci.note IS NOT NULL AND n.name_pcode_cf IN ('B3645', 'I1465', 'J6253', 'N4346', 'Q342', 'Q5152', 'S6135', 'V2323', 'V6343') AND mk.id > 4150659 AND t.phonetic_code LIKE '%5%';