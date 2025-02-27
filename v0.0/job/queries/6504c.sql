SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.kind_id > 1 AND t.series_years IN ('1893-1894', '1945-1947', '1953-1954', '1960-1960', '1962-1974', '1968-1972', '2006-2006') AND t.phonetic_code < 'N1256';