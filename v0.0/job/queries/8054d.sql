SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND k.phonetic_code IN ('B4314', 'D312', 'F4353', 'F6316', 'G5365', 'I2456', 'R6424', 'S6312', 'V3214', 'W235') AND t.season_nr < 1991 AND mc.note > '(2004) (USA) (TV) (2004-Present)';