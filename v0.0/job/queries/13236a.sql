SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.title LIKE '%O%' AND mk.keyword_id > 26935 AND k.keyword < 'boss-subordinate-relationship' AND t.season_nr IN (17, 19, 2012, 29);