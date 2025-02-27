SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND n.gender IN ('m') AND t.md5sum IN ('13a8362c6bd1ba0c425ada4a78633703', '2573c5b6bc240c131c47ac9c44f13bbc', '26f355b51f4c22962c344740d70ea0d4', '78903046e537f63b76b979e88b8f3457');