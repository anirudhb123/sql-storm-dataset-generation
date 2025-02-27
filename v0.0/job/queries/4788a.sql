SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mk.keyword_id < 130695 AND mk.id IN (1638792, 1738378, 2994278, 3532095, 3924550, 3938076, 4003731, 867495);