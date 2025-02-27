SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND k.phonetic_code > 'M2435' AND mi.note IS NOT NULL AND t.kind_id < 6 AND t.title LIKE '%Van%';