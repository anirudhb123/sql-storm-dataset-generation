
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    LISTAGG(DISTINCT k.keyword, ', ') AS keywords,
    LISTAGG(DISTINCT c.name, ', ') AS companies,
    LISTAGG(DISTINCT r.role, ', ') AS roles
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND c.country_code = 'USA'
GROUP BY 
    a.name, t.title, t.production_year
ORDER BY 
    t.production_year DESC, a.name;
