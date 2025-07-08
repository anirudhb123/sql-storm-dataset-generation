SELECT 
    DISTINCT a.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    k.keyword AS movie_keyword,
    r.role AS actor_role
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title m ON c.movie_id = m.id
JOIN 
    movie_keyword mk ON m.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    role_type r ON c.role_id = r.id
WHERE 
    m.production_year >= 2000
    AND k.keyword LIKE 'Action%'
ORDER BY 
    m.production_year ASC, 
    a.name ASC;
