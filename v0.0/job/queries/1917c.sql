SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mk.movie_id > 2185267 AND mk.id < 2909019 AND k.keyword < 'sales-competition' AND mi.note > 'Shawn Baker';