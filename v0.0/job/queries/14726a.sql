SELECT min(a1.name) AS writer_pseudo_name, min(t.title) AS movie_title
FROM aka_name AS a1, cast_info AS ci, company_name AS cn, movie_companies AS mc, name AS n1, role_type AS rt, title AS t
WHERE a1.person_id = n1.id AND n1.id = ci.person_id AND ci.movie_id = t.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.role_id = rt.id AND a1.person_id = ci.person_id AND ci.movie_id = mc.movie_id
AND t.series_years = '1962-1970' AND mc.note < '(1975) (Hungary) (theatrical)' AND t.production_year > 1916 AND a1.md5sum > '50be8fcebc4cf4e99750b22cf2f5b03e';