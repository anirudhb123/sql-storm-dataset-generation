SELECT 
    aka.title AS aka_title,
    title.title AS movie_title,
    person.name AS actor_name,
    role.role AS actor_role,
    company.name AS production_company,
    movie.production_year
FROM 
    aka_title AS aka
JOIN 
    title ON aka.movie_id = title.id
JOIN 
    cast_info AS cast ON cast.movie_id = title.id
JOIN 
    person_info AS person ON cast.person_id = person.person_id
JOIN 
    role_type AS role ON cast.role_id = role.id
JOIN 
    movie_companies AS mc ON title.id = mc.movie_id
JOIN 
    company_name AS company ON mc.company_id = company.id
WHERE 
    title.production_year BETWEEN 2000 AND 2020
ORDER BY 
    title.production_year DESC, actor_name;
