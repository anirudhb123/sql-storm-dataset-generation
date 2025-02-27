SELECT a.name AS actor_name, 
       t.title AS movie_title, 
       c.kind AS cast_type, 
       COALESCE(m.info, 'No info available') AS additional_info
FROM aka_name a
JOIN cast_info ci ON a.person_id = ci.person_id
JOIN title t ON ci.movie_id = t.id
JOIN comp_cast_type c ON ci.person_role_id = c.id
LEFT JOIN movie_info m ON t.id = m.movie_id AND m.info_type_id = (SELECT id FROM info_type WHERE info = 'Plot')
WHERE t.production_year >= 2000
AND c.kind IN (SELECT kind FROM company_type WHERE kind LIKE '%Production%')
ORDER BY a.name, t.production_year DESC
LIMIT 100;
