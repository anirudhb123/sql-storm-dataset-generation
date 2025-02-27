SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.production_year > 1914 AND t.phonetic_code IS NOT NULL AND mk.movie_id > 1581608 AND cn.name > 'Moon Men Media' AND cn.name_pcode_nf < 'L5131';