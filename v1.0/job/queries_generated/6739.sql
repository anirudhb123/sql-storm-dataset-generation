SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    m.production_year,
    r.role AS actor_role,
    GROUP_CONCAT(DISTINCT c.name ORDER BY c.name) AS company_names,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS movie_keywords
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
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
    m.production_year BETWEEN 2000 AND 2020
    AND c.country_code = 'USA'
GROUP BY 
    a.name, t.title, m.production_year, r.role
ORDER BY 
    m.production_year DESC, a.name;
