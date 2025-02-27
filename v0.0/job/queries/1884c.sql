SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND k.id IN (123132, 127931, 132411, 18473, 26323, 47860, 81054, 82132, 84714) AND t.md5sum > '75aaf71927a55919c850815a56ea57e7';