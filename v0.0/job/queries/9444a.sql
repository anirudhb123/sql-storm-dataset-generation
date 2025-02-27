SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND ci.nr_order > 51 AND n.name_pcode_nf IN ('E6132', 'G1263', 'G6462', 'I4142', 'W3232', 'Z2526') AND n.name_pcode_cf IS NOT NULL;