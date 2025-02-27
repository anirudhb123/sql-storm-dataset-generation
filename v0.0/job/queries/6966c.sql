SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.phonetic_code IS NOT NULL AND mi.info_type_id < 64 AND k.phonetic_code LIKE '%146%' AND mi.info < '$3,692 (USA) (27 October 2002) (1 screen)' AND mi.movie_id < 1425227;