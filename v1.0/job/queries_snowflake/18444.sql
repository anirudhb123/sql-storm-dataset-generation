SELECT t.title, a.name, c.nr_order, ci.kind 
FROM title t
JOIN cast_info c ON t.id = c.movie_id
JOIN aka_name a ON c.person_id = a.person_id
JOIN comp_cast_type ci ON c.person_role_id = ci.id
WHERE t.production_year = 2023
ORDER BY t.title;
