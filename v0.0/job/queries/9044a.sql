SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND k.keyword IN ('convict-leasing', 'hengsheng-jia', 'hit-with-a-tomahawk', 'police-riot', 'puking', 'reference-to-dianne-feinstein', 'wearing-disguises');