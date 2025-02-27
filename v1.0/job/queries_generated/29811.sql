SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS role,
    GROUP_CONCAT(k.keyword SEPARATOR ', ') AS keywords,
    m.production_year,
    ci.name AS company_name,
    mi.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    a.name LIKE '%Smith%' AND 
    mi.info LIKE '%winning%' AND 
    m.production_year BETWEEN 2000 AND 2023
GROUP BY 
    t.title, a.name, c.kind, m.production_year, ci.name, mi.info
ORDER BY 
    m.production_year DESC;
