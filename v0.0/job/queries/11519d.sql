SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.name_pcode_nf IN ('C6531', 'E145', 'G53', 'L245', 'N1245', 'Q3434', 'S4542', 'Y1314') AND t.title > 'Bouffe et malbouffe' AND t.series_years IN ('1964-1986', '1965-1981', '1973-1974', '1978-1990', '1988-1993', '1991-2004', '1998-????') AND mc.company_id < 103540 AND k.id < 29258 AND k.phonetic_code IS NOT NULL;