SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND k.phonetic_code IS NOT NULL AND t.season_nr < 1984 AND n.id > 1166602 AND mk.movie_id > 380338 AND k.id IN (102414, 21834, 25514, 28252, 35651, 64420, 72730, 80384, 98750);