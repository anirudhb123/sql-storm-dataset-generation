SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.role_id, 
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT co.name) AS companies
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
LEFT JOIN 
    movie_keyword mk ON t.movie_id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON t.movie_id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year > 2000
    AND c.nr_order < 5
GROUP BY 
    a.name, t.title, c.role_id
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
