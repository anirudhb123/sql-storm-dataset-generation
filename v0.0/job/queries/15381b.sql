SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mi.info_type_id IN (108, 3, 65, 66) AND t.imdb_index IN ('I', 'III', 'IX', 'XVIII', 'XXI') AND t.phonetic_code IS NOT NULL AND mi.info > 'Portugal:30 December 1997';