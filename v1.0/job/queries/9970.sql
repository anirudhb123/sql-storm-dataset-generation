
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    cn.name AS company_name,
    rt.role AS role_type,
    STRING_AGG(k.keyword, ', ') AS keywords
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    role_type rt ON ci.role_id = rt.id
LEFT JOIN 
    movie_keyword mk ON mk.movie_id = t.id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000
    AND cn.country_code = 'USA'
GROUP BY 
    a.name, t.title, t.production_year, cn.name, rt.role
HAVING 
    COUNT(k.id) > 1
ORDER BY 
    t.production_year DESC, a.name;
