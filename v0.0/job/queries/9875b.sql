SELECT min(a1.name) AS writer_pseudo_name, min(t.title) AS movie_title
FROM aka_name AS a1, cast_info AS ci, company_name AS cn, movie_companies AS mc, name AS n1, role_type AS rt, title AS t
WHERE a1.person_id = n1.id AND n1.id = ci.person_id AND ci.movie_id = t.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.role_id = rt.id AND a1.person_id = ci.person_id AND ci.movie_id = mc.movie_id
AND t.series_years IN ('1948-1957', '1955-1959', '1958-1992', '1968-1971', '1977-1992', '1980-2013', '1984-2005', '1988-1993', '1997-2005', '2003-2003');