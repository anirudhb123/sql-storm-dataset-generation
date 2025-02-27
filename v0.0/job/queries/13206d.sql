SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND n.name_pcode_cf IN ('A2643', 'A362', 'D245', 'F6412', 'N4525', 'S2612', 'S3634', 'Y2156') AND t.md5sum IS NOT NULL;