SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    ct.role AS role_type,
    COUNT(mk.keyword) AS keyword_count,
    ARRAY_AGG(DISTINCT mk.keyword) AS keywords,
    MIN(t.production_year) AS earliest_year,
    MAX(t.production_year) AS latest_year
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
WHERE 
    a.name IS NOT NULL
    AND t.production_year BETWEEN 1990 AND 2023
GROUP BY 
    a.name, t.title, c.kind, ct.role
ORDER BY 
    earliest_year ASC, actor_name ASC;
