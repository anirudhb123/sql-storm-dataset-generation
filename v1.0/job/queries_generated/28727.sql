SELECT 
    ak.name AS aka_name,
    ak.imdb_index AS aka_imdb_index,
    t.title AS movie_title,
    t.production_year AS movie_year,
    ct.kind AS company_type,
    c.name AS company_name,
    p.info AS person_info,
    COUNT(ci.id) AS total_cast_members
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    person_info p ON ak.person_id = p.person_id AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
WHERE 
    ak.name ILIKE '%John%' 
    AND t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    ak.name, ak.imdb_index, t.title, t.production_year, c.name, ct.kind, p.info
ORDER BY 
    total_cast_members DESC, t.production_year DESC;
