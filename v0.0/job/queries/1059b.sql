SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND mi.id > 8365673 AND k.phonetic_code LIKE '%6%' AND t.series_years < '1972-1972' AND t.id < 2136487;