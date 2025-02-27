SELECT min(mi_idx.info) AS rating, min(t.title) AS movie_title
FROM info_type AS it, keyword AS k, movie_info_idx AS mi_idx, movie_keyword AS mk, title AS t
WHERE t.id = mi_idx.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi_idx.movie_id AND k.id = mk.keyword_id AND it.id = mi_idx.info_type_id
AND t.title IN ('Hooray for Hollywood!', 'How Men of Different Races View Sex', 'Man and Woman', 'Rupert and the Compass', 'The Peasants and the Fairy', 'The Sinister Man', 'Tuko sa Madre Kakaw', 'Would Like to Meet') AND t.series_years IS NOT NULL;