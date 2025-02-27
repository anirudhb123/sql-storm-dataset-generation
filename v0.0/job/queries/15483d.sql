SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.kind_id > 0 AND t.series_years IS NOT NULL AND n.name_pcode_cf IN ('D4324', 'E5131', 'K4362', 'Q5261', 'R345', 'W1262') AND t.id < 1308266;