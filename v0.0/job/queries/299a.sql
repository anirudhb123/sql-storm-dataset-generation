SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND t.series_years LIKE '%1989%' AND cn.name_pcode_sf IN ('D3145', 'D5354', 'O2624', 'P6213', 'S5315', 'T4142', 'V4631');