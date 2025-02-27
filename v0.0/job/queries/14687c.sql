SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.id < 133675 AND k.phonetic_code IN ('E14', 'F6412', 'G532', 'H3626', 'L42', 'N3616', 'O1326', 'O143', 'R5251', 'U5165');