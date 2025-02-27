SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND k.keyword > 'lettering' AND t.id > 1799892 AND k.id IN (108128, 201, 2817, 81133, 81757, 91367) AND mi.id > 7530576;