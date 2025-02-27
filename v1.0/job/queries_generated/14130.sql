SELECT 
    name.name AS actor_name,
    title.title AS movie_title,
    aka_title.title AS aka_title,
    movie_info.info AS additional_info,
    company_name.name AS company_name
FROM 
    cast_info
JOIN 
    aka_name ON cast_info.person_id = aka_name.person_id
JOIN 
    title ON cast_info.movie_id = title.id
JOIN 
    aka_title ON title.id = aka_title.movie_id
JOIN 
    movie_info ON title.id = movie_info.movie_id
JOIN 
    movie_companies ON title.id = movie_companies.movie_id
JOIN 
    company_name ON movie_companies.company_id = company_name.id
WHERE 
    title.production_year >= 2000
ORDER BY 
    title.production_year DESC;
