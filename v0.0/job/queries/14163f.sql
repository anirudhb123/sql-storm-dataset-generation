SELECT min(k.keyword) AS movie_keyword, min(n.name) AS actor_name, min(t.title) AS hero_movie
FROM cast_info AS ci, keyword AS k, movie_keyword AS mk, name AS n, title AS t
WHERE k.id = mk.keyword_id AND t.id = mk.movie_id AND t.id = ci.movie_id AND ci.movie_id = mk.movie_id AND n.id = ci.person_id
AND t.title > '(2006-04-17)' AND ci.id < 4507962 AND t.md5sum > '1b01d51a1428cdbe26c8f8a4e9c42256' AND n.imdb_index IN ('CIX', 'CLVIII', 'CXXI', 'III', 'LXVIII', 'LXXXVI', 'XXVII', 'XXXI') AND mk.movie_id < 2487804;