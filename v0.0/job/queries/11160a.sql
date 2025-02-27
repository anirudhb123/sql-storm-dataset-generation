SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND ci.note > '(segment "Jump")' AND t.production_year IN (1899, 1903, 1917, 1924, 1932, 1957, 1971, 1972, 1981, 1984) AND t.series_years < '1993-1994' AND t.title > 'Wheel Was Here 5' AND n.surname_pcode IS NOT NULL AND n.name_pcode_nf IS NOT NULL;