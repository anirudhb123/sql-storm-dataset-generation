SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.title < 'Shen long' AND mi.id > 2098602 AND mi.info > 'Sweden:26 April 2013' AND k.id < 28119;