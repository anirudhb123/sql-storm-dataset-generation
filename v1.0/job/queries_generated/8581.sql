SELECT 
    DISTINCT a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.role_id,
    GROUP_CONCAT(DISTINCT kw.keyword) AS keywords,
    COUNT(DISTINCT mco.company_id) AS production_companies
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_companies mco ON t.id = mco.movie_id
WHERE 
    t.production_year >= 2000
GROUP BY 
    a.name, t.title, t.production_year, c.role_id
HAVING 
    COUNT(DISTINCT mco.company_id) > 1
ORDER BY 
    t.production_year DESC, a.name;
