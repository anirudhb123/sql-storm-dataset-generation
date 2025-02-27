SELECT min(t.title) AS movie_title
FROM keyword AS k, movie_info AS mi, movie_keyword AS mk, title AS t
WHERE t.id = mi.movie_id AND t.id = mk.movie_id AND mk.movie_id = mi.movie_id AND k.id = mk.keyword_id
AND t.kind_id = 2 AND mi.note IS NOT NULL AND mi.info_type_id > 50 AND t.md5sum > 'bc7e5cae6be9bdf39c88262ad68e6b50' AND k.phonetic_code IN ('C1265', 'C5162', 'E431', 'I263', 'I5616', 'J231', 'K153', 'N5413', 'O2163', 'Q256');