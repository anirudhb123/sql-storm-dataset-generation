SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(c.id) AS role_count,
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords,
    COUNT(DISTINCT mc.company_id) AS production_companies,
    pi.info AS actor_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    movie_keyword mk ON mk.movie_id = t.id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
LEFT JOIN 
    person_info pi ON pi.person_id = a.person_id 
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND k.keyword LIKE '%action%'
GROUP BY 
    a.name, t.title, t.production_year, pi.info
ORDER BY 
    t.production_year DESC, role_count DESC;
