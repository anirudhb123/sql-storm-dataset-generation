SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.md5sum IS NOT NULL AND cn.name < 'Infamous Black Productions' AND t.production_year IN (2015, 2019) AND cn.id < 177053 AND mc.movie_id < 2099630 AND t.phonetic_code > 'D3532';