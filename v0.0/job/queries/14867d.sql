SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND t.phonetic_code < 'M652' AND t.kind_id = 4 AND n.surname_pcode LIKE '%5%' AND k.phonetic_code IN ('D4352', 'H2145', 'H4535', 'K6363', 'M245', 'N3162', 'U1251', 'X415');