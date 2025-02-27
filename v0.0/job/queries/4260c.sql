SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mk.keyword_id < 65643 AND t.md5sum < 'eda4b80265f54a8fd7501c7a90799a24' AND mk.movie_id > 2300096;