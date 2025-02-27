SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.season_nr IS NOT NULL AND ci.role_id = 2 AND n.name_pcode_cf > 'F51' AND mk.id < 1080253 AND n.name_pcode_nf < 'H3625';