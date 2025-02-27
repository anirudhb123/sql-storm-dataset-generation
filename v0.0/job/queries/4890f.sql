SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND k.phonetic_code IN ('F2426', 'G6163', 'K25', 'L1232', 'O2521', 'O6524', 'S6141', 'T2365', 'T3435', 'Z5256') AND ci.note < '(as Ameagari Kesshitai)' AND n.name < 'Hipp Jr., Richard' AND n.name_pcode_cf IS NOT NULL AND n.md5sum IS NOT NULL;