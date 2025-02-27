SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.phonetic_code IS NOT NULL AND cn.country_code LIKE '%u%' AND cn.name > 'Attila Productions' AND mk.id < 3840451 AND k.phonetic_code > 'R261' AND cn.name_pcode_sf < 'E3451';