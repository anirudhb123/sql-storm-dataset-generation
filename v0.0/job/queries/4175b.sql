SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND mc.id > 511937 AND k.phonetic_code IN ('A4151', 'D1526', 'F313', 'K5352', 'M252', 'N26', 'P2316', 'P3564', 'R3534') AND cn.md5sum IS NOT NULL AND n.gender LIKE '%f%';