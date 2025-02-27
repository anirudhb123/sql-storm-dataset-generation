SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mi.info > 'Copyright 2010 Warner Bros. Entertainment Inc. All Rights Reserved. Production #3X5-471' AND t.id > 1092266 AND mi.note IS NOT NULL AND t.imdb_index > 'XI';