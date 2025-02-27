SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.season_nr IN (14, 1989, 1998, 3, 31, 33, 35, 48, 7, 74) AND t.title > 'XX.' AND mi.id > 9982383;