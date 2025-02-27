SELECT min(n.name) AS member_in_charnamed_movie
FROM cast_info AS ci, company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, name AS n, title AS t
WHERE n.id = ci.person_id AND ci.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.movie_id = mc.movie_id AND ci.movie_id = mk.movie_id AND mc.movie_id = mk.movie_id
AND t.title > 'Pfusch am Bau' AND t.episode_nr < 3831 AND k.phonetic_code IN ('A5362', 'M5363', 'O2626', 'R414', 'Y4353', 'Z5363') AND n.id > 3372949 AND cn.country_code > '[kz]';