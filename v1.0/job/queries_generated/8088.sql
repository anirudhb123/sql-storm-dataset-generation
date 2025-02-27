SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    m.production_year,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT c.name) AS companies,
    COUNT(DISTINCT p.id) AS role_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    person_info p ON a.id = p.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Biography')
GROUP BY 
    a.name, t.title, m.production_year
HAVING 
    COUNT(DISTINCT k.id) > 3
ORDER BY 
    m.production_year DESC, actor_name;
