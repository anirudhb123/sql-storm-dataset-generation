SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.id IN (1095953, 1592667, 20445, 211051, 219002, 2416100, 2437383, 256460, 596980, 915978) AND t.phonetic_code < 'W5312' AND n.id > 1936475 AND n.name_pcode_cf IS NOT NULL;