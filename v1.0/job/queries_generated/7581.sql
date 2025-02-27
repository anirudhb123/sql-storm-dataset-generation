SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.role_id,
    ci.kind,
    t.production_year,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND a.name LIKE 'A%'
GROUP BY 
    a.name, t.title, ci.role_id, c.kind, t.production_year
ORDER BY 
    t.production_year ASC, a.name ASC;
