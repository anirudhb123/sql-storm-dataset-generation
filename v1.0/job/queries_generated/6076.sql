SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS cast_type,
    YEAR(t.production_year) AS production_year,
    COUNT(DISTINCT k.keyword) AS keyword_count,
    GROUP_CONCAT(DISTINCT cn.name) AS company_names
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
GROUP BY 
    t.title, a.name, c.kind, t.production_year
ORDER BY 
    production_year DESC, movie_title ASC;
