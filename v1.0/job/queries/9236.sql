SELECT 
    n.name AS actor_name,
    a.title AS movie_title,
    ci.nr_order AS role_order,
    ct.kind AS company_type,
    m.production_year AS year,
    COUNT(DISTINCT k.keyword) AS keyword_count
FROM 
    name n
JOIN 
    cast_info ci ON n.id = ci.person_id
JOIN 
    aka_title a ON ci.movie_id = a.id
JOIN 
    movie_companies mc ON mc.movie_id = a.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON mk.movie_id = a.id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    title m ON m.id = a.movie_id
WHERE 
    m.production_year BETWEEN 1990 AND 2020
    AND k.keyword IS NOT NULL
GROUP BY 
    n.name, a.title, ci.nr_order, ct.kind, m.production_year
ORDER BY 
    year DESC, actor_name ASC;
