SELECT 
    n.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.kind AS role_type,
    GROUP_CONCAT(k.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name) AS production_companies
FROM 
    cast_info ci
JOIN 
    aka_name n ON ci.person_id = n.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type c ON ci.role_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    t.production_year >= 2000
    AND c.kind IN ('Actor', 'Actress')
GROUP BY 
    n.name, t.title, t.production_year, c.kind
ORDER BY 
    t.production_year DESC, n.name;
