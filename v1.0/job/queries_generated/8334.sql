SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS role_type,
    m.production_year,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword SEPARATOR ', ') AS keywords
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
    info_type it ON mi.info_type_id = it.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND it.info = 'Genre'
GROUP BY 
    a.name, t.title, c.kind, m.production_year
HAVING 
    COUNT(k.id) > 2
ORDER BY 
    a.name, m.production_year DESC;
