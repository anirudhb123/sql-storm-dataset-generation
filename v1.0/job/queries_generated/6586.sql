SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT c.kind) AS company_kinds
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_type c ON mc.company_type_id = c.id
WHERE 
    t.production_year >= 1990
GROUP BY 
    a.name, t.title, t.production_year
ORDER BY 
    a.name, t.production_year;
