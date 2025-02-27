SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND n.gender IN ('f') AND n.name_pcode_nf IN ('E3232', 'E5624', 'K6251', 'L4152', 'M4216', 'O2346', 'P2142', 'Q1523', 'Q3626', 'Y3215');