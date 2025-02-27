SELECT 
    at.title AS movie_title, 
    ak.name AS actor_name, 
    c.role_id AS role_id
FROM 
    aka_title at
JOIN 
    cast_info c ON at.id = c.movie_id
JOIN 
    aka_name ak ON c.person_id = ak.person_id
WHERE 
    at.production_year = 2023
ORDER BY 
    at.title, ak.name;
