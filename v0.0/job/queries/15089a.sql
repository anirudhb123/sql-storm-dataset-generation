SELECT min(a1.name) AS writer_pseudo_name, min(t.title) AS movie_title
FROM aka_name AS a1, cast_info AS ci, company_name AS cn, movie_companies AS mc, name AS n1, role_type AS rt, title AS t
WHERE a1.person_id = n1.id AND n1.id = ci.person_id AND ci.movie_id = t.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.role_id = rt.id AND a1.person_id = ci.person_id AND ci.movie_id = mc.movie_id
AND n1.name_pcode_nf > 'D3241' AND t.series_years > '1983-1988' AND a1.name_pcode_nf < 'T6165' AND ci.person_role_id > 1702846 AND mc.note > '(2003) (Finland) (TV) (TV2)';