SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND t.md5sum LIKE '%c%' AND k.id IN (129344, 131832, 37714, 66742, 81026, 8675, 91928, 95585) AND mk.id > 593788 AND t.season_nr IN (10, 1984, 1998, 25, 30, 57, 7);