SELECT 
    movie.title AS movie_title,
    person.name AS actor_name,
    character.name AS character_name,
    production_year
FROM 
    title AS movie
JOIN 
    cast_info AS cast ON movie.id = cast.movie_id
JOIN 
    aka_name AS person ON cast.person_id = person.person_id
JOIN 
    char_name AS character ON cast.role_id = character.id
WHERE 
    movie.production_year >= 2000
ORDER BY 
    movie.production_year DESC;
