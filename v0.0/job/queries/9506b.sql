SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.country_code < '[as]' AND t.kind_id < 2 AND mk.movie_id > 2020016 AND k.phonetic_code IN ('E6462', 'H1626', 'H435', 'M2654', 'P4162', 'S1254', 'S3635', 'T162') AND mk.keyword_id < 34505;