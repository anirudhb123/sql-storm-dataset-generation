SELECT a.name AS aka_name,
       t.title AS movie_title,
       p.info AS person_info,
       c.kind AS cast_type,
       r.role AS role_type
FROM aka_name a
JOIN cast_info ci ON a.person_id = ci.person_id
JOIN title t ON ci.movie_id = t.id
JOIN person_info p ON a.person_id = p.person_id
JOIN comp_cast_type c ON ci.person_role_id = c.id
JOIN role_type r ON ci.role_id = r.id
WHERE t.production_year >= 2000
ORDER BY t.production_year DESC;
