SELECT 
    DISTINCT a.name AS actor_name, 
    t.title AS movie_title, 
    t.production_year AS production_year, 
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
    c.kind AS comp_type,
    COUNT(DISTINCT ci.person_role_id) AS total_roles
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000
    AND c.kind IS NOT NULL
GROUP BY 
    a.name, t.title, t.production_year, c.kind
HAVING 
    COUNT(DISTINCT ci.role_id) > 0
ORDER BY 
    production_year DESC, actor_name;
