SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS cast_type,
    COUNT(DISTINCT m.id) AS total_movies,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords,
    STRING_AGG(DISTINCT comp.name, ', ') AS companies
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    complete_cast cc ON cc.movie_id = t.id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_name comp ON mc.company_id = comp.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    kind_type kt ON t.kind_id = kt.id
WHERE 
    t.production_year >= 2000
    AND a.name IS NOT NULL
GROUP BY 
    t.title, a.name, c.kind
ORDER BY 
    total_movies DESC, movie_title ASC;
