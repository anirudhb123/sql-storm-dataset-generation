SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND cn.md5sum IN ('a821d45d637a4ca75c6f8376b2c165c7', 'dde636563031f3f3f9bd21a4b6b5e98e') AND n.gender IN ('m') AND t.md5sum > '3a1bb8d92f8a3dd128b5560af25d41c6';