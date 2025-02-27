SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    r.role AS role_name,
    c.kind AS cast_kind,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT c2.name) AS companies
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
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
LEFT JOIN 
    movie_companies mc2 ON t.id = mc2.movie_id
LEFT JOIN 
    company_name c2 ON mc2.company_id = c2.id
WHERE 
    t.production_year >= 2000
    AND c.country_code = 'USA'
GROUP BY 
    a.name, t.title, t.production_year, r.role, c.kind
ORDER BY 
    t.production_year DESC, a.name ASC;
