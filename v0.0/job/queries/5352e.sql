SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.series_years > '1991-1997' AND t.imdb_index LIKE '%V%' AND n.gender = 'f' AND ci.person_role_id < 1987509 AND n.md5sum < 'b09de332a21783837d4c9a9693efc61e';