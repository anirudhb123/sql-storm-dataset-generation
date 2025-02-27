SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND t.title < 'Ploeger Delikatessen' AND t.md5sum > 'ddee2031c5aed9128886df64a9ce7221' AND mc.company_type_id IN (2) AND ci.nr_order IN (223, 3303) AND t.episode_of_id < 1353237;