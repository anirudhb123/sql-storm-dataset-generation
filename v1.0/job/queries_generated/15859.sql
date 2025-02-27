SELECT a.name AS actor_name, t.title AS movie_title, c.note AS role_note
FROM aka_name AS a
JOIN cast_info AS ci ON a.person_id = ci.person_id
JOIN title AS t ON ci.movie_id = t.id
JOIN role_type AS r ON ci.role_id = r.id
WHERE t.production_year = 2020
ORDER BY a.name;
