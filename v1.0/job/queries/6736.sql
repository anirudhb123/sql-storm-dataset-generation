
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.role_id,
    ct.kind AS company_type,
    STRING_AGG(DISTINCT k.keyword, ',') AS keywords
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND ct.kind = 'Distributor'
GROUP BY 
    a.name, t.title, t.production_year, c.role_id, ct.kind
ORDER BY 
    t.production_year DESC, a.name ASC;
