SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS role,
    m.production_year,
    GROUP_CONCAT(DISTINCT kw.keyword) AS keywords
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
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    mi.info_type_id = (SELECT id FROM info_type WHERE info = 'BoxOffice')
    AND a.name IS NOT NULL
GROUP BY 
    a.name, t.title, c.kind, m.production_year
HAVING 
    COUNT(DISTINCT kw.keyword) > 1
ORDER BY 
    m.production_year DESC, a.name ASC;
