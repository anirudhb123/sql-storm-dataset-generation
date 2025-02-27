SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.production_year < 1955 AND k.phonetic_code IN ('B1531', 'D4123', 'F3631', 'N1353', 'P624', 'W12', 'W5315') AND n.surname_pcode LIKE '%4%' AND t.phonetic_code > 'N3262';