SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND cn.id > 97781 AND t.production_year < 2019 AND n.surname_pcode > 'T234' AND mk.id IN (1834861, 2001069, 2459797, 2859165, 2927960, 3234392, 3894174, 4381151) AND t.phonetic_code IS NOT NULL;