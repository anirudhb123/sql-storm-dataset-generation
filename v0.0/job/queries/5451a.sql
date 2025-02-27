SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND n.name_pcode_nf IS NOT NULL AND n.md5sum > '797ab629510827b31d38c8b629cc0af6' AND mk.id IN (1590952, 2627848, 3012641, 3032242, 3139059, 3328957, 353317, 3969917, 4454727, 991434) AND n.surname_pcode IS NOT NULL AND n.name_pcode_cf LIKE '%5%' AND ci.role_id = 3;