SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND k.phonetic_code < 'S2621' AND mc.note > '(2009) (USA) (DVD) (Blu-ray) (unrated)' AND mc.company_id > 80463 AND k.keyword < 'glove-slap' AND t.series_years IS NOT NULL;