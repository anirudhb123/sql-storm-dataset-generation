SELECT 
    aka_name.name AS actor_name,
    title.title AS movie_title,
    title.production_year,
    role_type.role AS role_name
FROM 
    aka_name
JOIN 
    cast_info ON aka_name.person_id = cast_info.person_id
JOIN 
    title ON cast_info.movie_id = title.id
JOIN 
    role_type ON cast_info.role_id = role_type.id
WHERE 
    title.production_year >= 2000
ORDER BY 
    title.production_year DESC;
