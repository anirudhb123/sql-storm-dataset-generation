SELECT a.name AS actor_name, t.title AS movie_title, c.kind AS cast_type
FROM aka_name AS a
JOIN cast_info AS ci ON a.person_id = ci.person_id
JOIN title AS t ON ci.movie_id = t.id
JOIN comp_cast_type AS c ON ci.person_role_id = c.id
WHERE t.production_year = 2023
ORDER BY a.name, t.title;
