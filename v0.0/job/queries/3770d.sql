SELECT min(a1.name) AS writer_pseudo_name, min(t.title) AS movie_title
FROM aka_name AS a1, cast_info AS ci, company_name AS cn, movie_companies AS mc, name AS n1, role_type AS rt, title AS t
WHERE a1.person_id = n1.id AND n1.id = ci.person_id AND ci.movie_id = t.id AND t.id = mc.movie_id AND mc.company_id = cn.id AND ci.role_id = rt.id AND a1.person_id = ci.person_id AND ci.movie_id = mc.movie_id
AND t.season_nr < 53 AND ci.id < 17972072 AND a1.name_pcode_cf IN ('A6314', 'C3463', 'G126', 'I6321', 'N142', 'O5456', 'T1212', 'U2512', 'V6124', 'Z1234');