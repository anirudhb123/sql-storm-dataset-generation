SELECT min(a1.name) AS writer_pseudo_name, min(t.title) AS movie_title
FROM aka_name AS a1, cast_info AS ci, company_name AS cn, movie_companies AS mc, name AS n1, role_type AS rt, title AS t
WHERE a1.person_id = n1.id AND n1.id = ci.person_id AND ci.movie_id = t.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.role_id = rt.id AND a1.person_id = ci.person_id AND ci.movie_id = mc.movie_id
AND n1.md5sum < '0f5725c6eaf5d7f91d3a32d78e62afbf' AND t.imdb_index IN ('I', 'III', 'IX', 'VI', 'XVI', 'XX', 'XXI', 'XXII', 'XXIII') AND ci.role_id = 11 AND t.id > 1498557;