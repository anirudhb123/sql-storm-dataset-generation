SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.title > 'Forbidden Love: The Story of Bronia and Gerhard' AND mk.keyword_id IN (106359, 26004, 32490, 39190, 44090, 55459, 65003, 96224);