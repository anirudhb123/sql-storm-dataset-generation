SELECT 
    aka.name AS aka_name,
    title.title AS movie_title,
    company.name AS company_name,
    person_info.info AS person_info,
    role_type.role AS role_name
FROM 
    aka_name AS aka
JOIN 
    cast_info AS cast ON aka.person_id = cast.person_id
JOIN 
    title ON cast.movie_id = title.id
JOIN 
    movie_companies AS mc ON title.id = mc.movie_id
JOIN 
    company_name AS company ON mc.company_id = company.id
JOIN 
    person_info ON aka.person_id = person_info.person_id
JOIN 
    role_type ON cast.role_id = role_type.id
WHERE 
    title.production_year > 2000
ORDER BY 
    title.production_year DESC, aka.name;
