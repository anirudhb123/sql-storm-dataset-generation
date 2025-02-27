SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.season_nr < 10 AND t.phonetic_code LIKE '%43%' AND k.id IN (115327, 122544, 12606, 17647, 25889, 36231, 40807, 97092) AND n.md5sum < 'f2a14fdb172e2d3685b7a3950196e5ce';