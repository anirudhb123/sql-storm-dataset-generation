SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND k.phonetic_code IN ('F6512', 'G615', 'P6241', 'U2414') AND t.phonetic_code < 'G142' AND t.kind_id IN (0, 1, 2, 4, 6, 7);