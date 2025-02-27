SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mi.note IN ('(Fukuoka Asian Film Festival)', '(VHS) (cut)', '([A]FEFV - Ambiental Experimental Film and Video Festival)', '(season 2 - episode 10)', 'Andrew Delaplaine', 'Anna R. Swenson') AND mk.id > 1601637;