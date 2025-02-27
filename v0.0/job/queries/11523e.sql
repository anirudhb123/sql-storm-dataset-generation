SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND n.name_pcode_cf < 'H2156' AND t.md5sum > 'c5a70f4f6353c9fc964f01d22bbbb71c' AND t.series_years < '1986-1997' AND mk.id < 740912;