SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mk.id IN (1051552, 1628239, 2474479, 2656861, 3808586, 641968, 774000) AND mi.info > 'Poland:22 November 2005';