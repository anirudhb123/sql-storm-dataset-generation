SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND k.id > 28036 AND t.title < 'Aflevering 745' AND k.keyword > 'k.i.t.t.-car' AND t.production_year > 1903;