SELECT 
    a.name AS actor_name,
    GROUP_CONCAT(DISTINCT t.title ORDER BY t.production_year DESC) AS titles,
    COUNT(DISTINCT t.id) AS title_count,
    MIN(t.production_year) AS earliest_year,
    MAX(t.production_year) AS latest_year,
    c.kind AS cast_type,
    cp.name AS company_name,
    k.keyword AS associated_keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cp ON mc.company_id = cp.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year > 2000
GROUP BY 
    a.name, c.kind, cp.name, k.keyword
HAVING 
    COUNT(DISTINCT t.id) > 5
ORDER BY 
    title_count DESC, latest_year DESC;
