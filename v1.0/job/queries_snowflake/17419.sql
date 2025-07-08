SELECT 
    title.title AS movie_title,
    aka_name.name AS actor_name,
    role_type.role AS role
FROM 
    title
JOIN 
    complete_cast ON title.id = complete_cast.movie_id
JOIN 
    cast_info ON complete_cast.subject_id = cast_info.person_id
JOIN 
    aka_name ON cast_info.person_id = aka_name.person_id
JOIN 
    role_type ON cast_info.role_id = role_type.id
WHERE 
    title.production_year = 2020
ORDER BY 
    title.title;
