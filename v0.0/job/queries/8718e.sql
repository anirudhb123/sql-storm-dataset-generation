SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND ci.movie_id > 956690 AND t.md5sum < '678f985e5c3fd4e38f13112ec9ed0f22' AND k.phonetic_code > 'G3623' AND mk.movie_id > 1349979;