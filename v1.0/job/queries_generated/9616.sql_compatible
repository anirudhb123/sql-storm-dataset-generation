
SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.nr_order,
    STRING_AGG(DISTINCT kw.keyword, ', ') AS keywords,
    STRING_AGG(DISTINCT co.name, ', ') AS companies
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
WHERE 
    t.production_year >= 2000 
    AND a.name IS NOT NULL
GROUP BY 
    a.name, t.title, t.production_year, c.nr_order
ORDER BY 
    t.production_year DESC, actor_name ASC;
