SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mi.info < 'Kenny, Glenn. "Reviews: Sunshine State (***)". In: "Premiere" (USA), Vol. 15, Iss. 11, July 2002, Pg. 22-23, (MG)';