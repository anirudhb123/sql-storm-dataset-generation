SELECT 
    aka_name.name AS aka_name,
    title.title AS movie_title,
    person_info.info AS person_info,
    movie_info.info AS movie_info
FROM 
    aka_name
JOIN 
    cast_info ON aka_name.person_id = cast_info.person_id
JOIN 
    title ON cast_info.movie_id = title.id
JOIN 
    person_info ON aka_name.person_id = person_info.person_id
JOIN 
    movie_info ON title.id = movie_info.movie_id
WHERE 
    title.production_year >= 2000
ORDER BY 
    title.production_year DESC, aka_name.name;
