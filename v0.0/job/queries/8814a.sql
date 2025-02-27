SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mi.info_type_id > 47 AND mi.movie_id < 1418941 AND mi.info > 'Escaped convict Sam Gillen single handedly takes on ruthless developers determined to evict Clydie - a widow with two young children. Nobody knows who Sam is.';