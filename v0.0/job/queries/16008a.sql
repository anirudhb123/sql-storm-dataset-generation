SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mk.id IN (1994716, 204127, 2844386, 2954697, 3388755, 3664011, 4059968, 4225339);