SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND n.surname_pcode IS NOT NULL AND t.phonetic_code IN ('A5631', 'G626', 'G6513', 'K3141', 'L35', 'M2165', 'R5251', 'T5123') AND ci.note IS NOT NULL;