SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND n.md5sum IN ('2160fc8a7cf6ab35e6ff7ea01ffd6b25', '69c13400a2d51c921e93592da1f28ee3', 'aec374d1c912897abaed814502c13e6c', 'c5a35d71f0e6572ffde1e1cf41861e7b', 'd34f366cad6446f15b421d86243689b1') AND t.production_year < 2009 AND t.title > 'Feature Story';