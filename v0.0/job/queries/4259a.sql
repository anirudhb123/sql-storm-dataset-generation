SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.name_pcode_sf IN ('G4512') AND t.md5sum < '97c8ecd1d98d94178fab5d2a0b2db7e7' AND t.imdb_index < 'IX';