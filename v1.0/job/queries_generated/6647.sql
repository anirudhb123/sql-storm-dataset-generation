SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(mk.keyword) AS keyword_count,
    STRING_AGG(DISTINCT mk.keyword, ', ') AS keywords,
    GROUP_CONCAT(DISTINCT c.kind) AS company_types,
    MIN(pi.info) AS actor_bio
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
LEFT JOIN 
    person_info pi ON a.person_id = pi.person_id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND a.name IS NOT NULL
GROUP BY 
    a.name, t.title, t.production_year
ORDER BY 
    t.production_year DESC, actor_name;
