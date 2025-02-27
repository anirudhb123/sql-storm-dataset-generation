SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.md5sum > '5bc5734bfbb5b7e95b297cd6ce62ddc7' AND t.kind_id IN (0, 1, 3, 4, 6, 7) AND cn.name_pcode_sf > 'E6125' AND t.season_nr IN (23, 36, 62, 67) AND t.phonetic_code > 'N3465';