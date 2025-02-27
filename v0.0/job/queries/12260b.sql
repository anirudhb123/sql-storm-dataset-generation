SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND t.title > 'Paxton Petty' AND n.surname_pcode IS NOT NULL AND k.phonetic_code IN ('A31', 'F6145', 'G2165', 'H1626', 'N3543', 'P3524', 'S4265', 'V123', 'W3451') AND mk.movie_id < 2457029;