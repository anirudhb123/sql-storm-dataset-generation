SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    r.role AS cast_role,
    c.name AS company_name,
    k.keyword AS movie_keyword,
    ARRAY_AGG(DISTINCT p.info) AS person_info,
    COUNT(DISTINCT m.id) AS total_movies
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    c.country_code = 'USA' AND 
    t.production_year >= 2000
GROUP BY 
    a.id, t.id, r.id, c.id, k.id
ORDER BY 
    total_movies DESC, aka_name ASC;
