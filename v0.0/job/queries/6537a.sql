SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.md5sum > '1ae59e79403a4fcc6520b8a88ea3e1e4' AND t.imdb_index IN ('I', 'IV', 'XV', 'XVIII', 'XX');