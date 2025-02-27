SELECT 
    a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    GROUP_CONCAT(DISTINCT r.role ORDER BY r.role) AS roles,
    c.name AS company_name,
    k.keyword AS movie_keywords
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title m ON ci.movie_id = m.id
JOIN 
    movie_companies mc ON m.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_keyword mk ON m.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    role_type r ON ci.role_id = r.id
WHERE 
    m.production_year BETWEEN 2000 AND 2020
    AND c.country_code = 'USA'
GROUP BY 
    a.name, m.title, m.production_year, c.name
ORDER BY 
    m.production_year DESC, a.name;
