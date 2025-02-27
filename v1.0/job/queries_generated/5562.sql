SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.kind AS company_type,
    GROUP_CONCAT(DISTINCT kw.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT ci.role_id) AS roles
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    t.production_year >= 2000
AND 
    a.name IS NOT NULL
GROUP BY 
    a.name, t.title, t.production_year, c.kind
ORDER BY 
    t.production_year DESC, a.name;
