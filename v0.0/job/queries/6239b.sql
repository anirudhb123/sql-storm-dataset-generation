SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.phonetic_code > 'U5214' AND cn.name_pcode_nf < 'E5143' AND mk.movie_id > 1953028 AND t.production_year = 1991 AND cn.country_code > '[me]';