
SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS cast_type, 
    ct.kind AS company_type, 
    STRING_AGG(DISTINCT k.keyword, ',') AS keywords,
    COUNT(DISTINCT ci.person_id) AS num_cast_members
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    a.name, t.title, c.kind, ct.kind
HAVING 
    COUNT(DISTINCT ci.movie_id) > 5
ORDER BY 
    num_cast_members DESC, movie_title ASC;
