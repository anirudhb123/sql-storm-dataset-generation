SELECT 
    title.title AS movie_title,
    aka_name.name AS actor_name,
    company_name.name AS company_name,
    movie_info.info AS movie_info
FROM 
    title
JOIN 
    aka_title ON title.id = aka_title.movie_id
JOIN 
    cast_info ON aka_title.id = cast_info.movie_id
JOIN 
    aka_name ON cast_info.person_id = aka_name.person_id
JOIN 
    movie_companies ON title.id = movie_companies.movie_id
JOIN 
    company_name ON movie_companies.company_id = company_name.id
JOIN 
    movie_info ON title.id = movie_info.movie_id
WHERE 
    title.production_year >= 2000
ORDER BY 
    title.production_year DESC, 
    actor_name ASC;
