SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND ci.role_id IN (1, 10, 11, 2, 3, 4, 6, 7, 9) AND n.name_pcode_nf > 'F126' AND cn.id IN (101767, 110950, 184155, 198714, 200158, 225015, 81107, 8361, 93260) AND k.phonetic_code LIKE '%D%';