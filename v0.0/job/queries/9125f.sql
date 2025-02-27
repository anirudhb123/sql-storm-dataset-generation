SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND mk.id > 4167003 AND ci.role_id IN (11, 2, 5, 6) AND n.name > 'Vu, Xuan Truong' AND mk.keyword_id IN (115814, 119769, 119968, 130544, 21919, 29880, 50355, 56995, 73593);