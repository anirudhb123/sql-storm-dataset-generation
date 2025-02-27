SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.phonetic_code IN ('A4341', 'E5316', 'F2535', 'I3431', 'K5362', 'M345', 'U524') AND t.kind_id < 2;