SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND t.imdb_index IS NOT NULL AND k.phonetic_code IN ('C524', 'E4121', 'J145', 'P6314', 'R4145', 'S5413', 'Z5354') AND t.md5sum > 'e4926f813a26608847c8c55bddd94651';