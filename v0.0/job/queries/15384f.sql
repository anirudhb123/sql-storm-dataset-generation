SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND k.phonetic_code IS NOT NULL AND t.phonetic_code IS NOT NULL AND n.name_pcode_cf IN ('D315', 'H164', 'H3525', 'K564', 'O4213', 'S5636', 'U3151') AND t.imdb_index IN ('I', 'VI', 'XIII', 'XXII', 'XXIII') AND n.gender IN ('f') AND t.production_year > 1901;