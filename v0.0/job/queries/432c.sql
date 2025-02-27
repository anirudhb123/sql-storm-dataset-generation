SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mi.movie_id < 501013 AND t.phonetic_code > 'Q5246' AND mi.info_type_id IN (107, 109, 7, 73, 84, 87) AND mk.keyword_id IN (101028, 119077, 18724, 28386, 34446, 45428, 6309, 76209, 89227) AND t.production_year IS NOT NULL;