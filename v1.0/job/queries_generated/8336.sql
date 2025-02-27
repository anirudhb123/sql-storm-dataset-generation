SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    YEAR(t.production_year) AS production_year, 
    GROUP_CONCAT(DISTINCT k.keyword SEPARATOR ', ') AS keywords, 
    GROUP_CONCAT(DISTINCT c.name SEPARATOR ', ') AS companies
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name c ON mc.company_id = c.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020 
    AND a.name IS NOT NULL 
    AND k.keyword IS NOT NULL
GROUP BY 
    a.name, t.title, t.production_year
ORDER BY 
    t.production_year DESC, a.name;
