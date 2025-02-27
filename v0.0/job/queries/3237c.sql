SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mi.id IN (11056867, 12688511, 12981814, 1481664, 3876190, 6901667, 8014389, 8476117, 9351276, 9876795);