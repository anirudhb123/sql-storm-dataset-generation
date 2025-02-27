SELECT min(t.title) AS movie_title
FROM company_name AS cn, keyword AS k, movie_companies AS mc, movie_keyword AS mk, title AS t
WHERE cn.id = mc.company_id AND mc.movie_id = t.id AND t.id = mk.movie_id AND mk.keyword_id = k.id AND mc.movie_id = mk.movie_id
AND cn.name < 'Conventry Films' AND cn.country_code IS NOT NULL AND t.series_years IN ('1941-1942', '1952-1954', '1969-1996', '1971-1980', '1972-2004', '1973-????', '1978-2008', '2005-2007') AND cn.name_pcode_nf LIKE '%6%' AND t.md5sum < '73b3b74df72db04da1ab02cbd42fa2b1';