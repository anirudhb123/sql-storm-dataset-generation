SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND ci.role_id IN (1, 10, 11, 4, 5, 6, 7, 8, 9) AND ci.nr_order > 20002 AND n.imdb_index < 'X' AND cn.md5sum < '5b856dd970de24e6c3ce41e3811cc4fc';