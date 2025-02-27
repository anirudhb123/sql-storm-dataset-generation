SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND k.keyword < 'brawler' AND mi.note IS NOT NULL AND t.md5sum > 'd2dbf024509a0403832a457611c8d407' AND t.season_nr IN (17, 20, 23, 29, 44, 51, 56, 91) AND mi.info_type_id IN (102, 104, 108, 17, 18, 2, 43, 54, 84);