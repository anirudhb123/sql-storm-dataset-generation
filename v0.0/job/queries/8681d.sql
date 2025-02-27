SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.title < 'Pecadores' AND t.phonetic_code IN ('A3656', 'A6512', 'B1632', 'C1245', 'C654', 'F1352', 'N4561', 'O15', 'P2563', 'Z2314');