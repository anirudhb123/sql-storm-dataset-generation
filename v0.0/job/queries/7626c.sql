SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND k.keyword > 'nuclear-industry' AND t.kind_id < 4 AND mk.keyword_id > 59472 AND mi.info LIKE '%7%' AND t.production_year = 2005;