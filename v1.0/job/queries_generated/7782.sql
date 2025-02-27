SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS character_type,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    GROUP_CONCAT(DISTINCT co.name) AS companies_produced,
    MIN(t.production_year) AS earliest_year,
    MAX(t.production_year) AS latest_year
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
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year > 2000
    AND r.role LIKE '%actor%'
GROUP BY 
    a.name, t.title, c.kind
ORDER BY 
    keyword_count DESC, earliest_year ASC;
