SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS role_type, 
    m.production_year,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info m ON t.id = m.movie_id
GROUP BY 
    a.name, t.title, c.kind, m.production_year
ORDER BY 
    m.production_year DESC, a.name;
