SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND k.id > 50308 AND ci.role_id IN (1, 10, 11, 2, 3, 4, 5, 6, 8, 9) AND k.phonetic_code < 'T5652' AND ci.note IS NOT NULL AND n.name_pcode_cf > 'Y2531' AND ci.nr_order IS NOT NULL;