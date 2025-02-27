SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND mc.id > 1312917 AND cn.md5sum < 'db3b326c3d9409f8e226aa5fb73d2550' AND k.phonetic_code IN ('C5124', 'D5', 'E4136', 'J1616', 'L145', 'N1426', 'R2121', 'V3143');