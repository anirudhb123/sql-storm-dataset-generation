SELECT 
    title.title AS movie_title,
    aka_name.name AS actor_name,
    role_type.role AS actor_role
FROM 
    title
JOIN 
    movie_companies ON title.id = movie_companies.movie_id
JOIN 
    cast_info ON title.id = cast_info.movie_id
JOIN 
    aka_name ON cast_info.person_id = aka_name.person_id
JOIN 
    role_type ON cast_info.role_id = role_type.id
WHERE 
    title.production_year >= 2000
ORDER BY 
    title.title;
