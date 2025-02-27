SELECT 
    aka_name.name AS aka_name, 
    title.title AS movie_title, 
    company_name.name AS company_name, 
    person_info.info AS person_info 
FROM 
    aka_name
JOIN 
    cast_info ON aka_name.person_id = cast_info.person_id
JOIN 
    title ON cast_info.movie_id = title.id
JOIN 
    movie_companies ON title.id = movie_companies.movie_id
JOIN 
    company_name ON movie_companies.company_id = company_name.id
JOIN 
    person_info ON aka_name.person_id = person_info.person_id
WHERE 
    title.production_year BETWEEN 2000 AND 2020
ORDER BY 
    title.title;
