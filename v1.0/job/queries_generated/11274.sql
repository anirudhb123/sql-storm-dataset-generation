SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS character_role,
    y.production_year,
    GROUP_CONCAT(k.keyword) AS keywords
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    company_name co ON mi.movie_id = co.imdb_id
WHERE 
    mi.info_type_id = (
        SELECT id FROM info_type WHERE info = 'Description'
    )
GROUP BY 
    a.name, t.title, c.kind, y.production_year
ORDER BY 
    y.production_year DESC;
