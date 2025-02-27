SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND n.md5sum IN ('151d1f27fea25812ae1865c60296a711', '210758063b694337a37fd233696f8ae5', '5cb55b3c57c5101557bf4d673a7b42a5', 'd59d328c4b38af18231785417387f664');