SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mi.info > 'Kienzle, William X.. "Rosary Murders, The". (USA), Andrews & McMeel, Inc., March 1979, Pg. 257, (BK), ISBN-10: 0836261011' AND t.title < 'Bittere Pil' AND k.keyword LIKE '%leaf%' AND mi.note > 'fred@vanderpoel.com' AND mk.keyword_id > 42501;