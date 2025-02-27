SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND n.name_pcode_nf > 'D2613' AND t.id IN (1311609, 1453182, 185445, 2203594, 2297017, 260758, 421150, 589294) AND t.md5sum > '93b6bb31cc8884d697defe63bd4afc3b';