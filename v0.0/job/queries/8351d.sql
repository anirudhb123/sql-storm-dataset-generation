SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND mk.id < 1665507 AND t.phonetic_code IN ('A4513', 'D6453', 'N3412', 'P346', 'Q415', 'T3452', 'V6241', 'V6313', 'W3425') AND mk.keyword_id < 9823;