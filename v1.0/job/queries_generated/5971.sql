SELECT 
    a.id AS aka_id, 
    a.name AS aka_name, 
    t.title AS movie_title, 
    t.production_year, 
    n.gender, 
    c.kind AS cast_role, 
    co.name AS company_name 
FROM 
    aka_name a 
JOIN 
    cast_info c ON a.person_id = c.person_id 
JOIN 
    title t ON c.movie_id = t.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name co ON mc.company_id = co.id 
JOIN 
    name n ON a.person_id = n.imdb_id 
WHERE 
    t.production_year >= 2000 
    AND co.country_code = 'USA' 
ORDER BY 
    t.production_year DESC, 
    a.name;
