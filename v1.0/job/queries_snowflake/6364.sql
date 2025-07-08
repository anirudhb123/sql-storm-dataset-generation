
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    r.role AS character_name,
    LISTAGG(DISTINCT c.name, ', ' ) WITHIN GROUP (ORDER BY c.name ASC) AS company_names,
    LISTAGG(DISTINCT k.keyword, ', ' ) WITHIN GROUP (ORDER BY k.keyword ASC) AS keywords
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000
    AND c.country_code = 'USA'
    AND r.role IN (SELECT role FROM role_type WHERE role LIKE '%Lead%')
GROUP BY 
    a.name, t.title, t.production_year, r.role
ORDER BY 
    t.production_year DESC, a.name;
