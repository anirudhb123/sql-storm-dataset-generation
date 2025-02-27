SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.title > 'Birthday Soup/Polar Bear/Gone Fishing' AND t.season_nr < 28 AND mi.movie_id > 941097 AND t.kind_id IN (0, 1, 3, 6, 7);