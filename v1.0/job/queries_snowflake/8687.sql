
SELECT 
    p.name AS actor_name,
    m.title AS movie_title,
    m.production_year,
    c.role_id,
    r.role AS role_name,
    LISTAGG(DISTINCT k.keyword, ', ') WITHIN GROUP (ORDER BY k.keyword) AS keywords,
    LISTAGG(DISTINCT cn.name, ', ') WITHIN GROUP (ORDER BY cn.name) AS company_names
FROM 
    cast_info c
JOIN 
    aka_name p ON c.person_id = p.person_id
JOIN 
    title m ON c.movie_id = m.id
JOIN 
    role_type r ON c.role_id = r.id
LEFT JOIN 
    movie_keyword mk ON m.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_companies mc ON m.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    m.production_year BETWEEN 2000 AND 2020
AND 
    r.role IN ('Actor', 'Director')
GROUP BY 
    p.name, m.title, m.production_year, c.role_id, r.role
ORDER BY 
    m.production_year DESC, actor_name;
