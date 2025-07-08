SELECT 
    ak.name AS aka_name,
    at.title AS movie_title,
    ct.kind AS company_type,
    COUNT(ci.id) AS cast_count
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    aka_title at ON ci.movie_id = at.movie_id
JOIN 
    movie_companies mc ON at.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
GROUP BY 
    ak.name, at.title, ct.kind
ORDER BY 
    cast_count DESC;
