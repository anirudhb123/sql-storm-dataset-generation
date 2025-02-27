SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.id > 1862886 AND mk.keyword_id < 29633 AND k.keyword < 'central-europe' AND t.production_year < 1916;