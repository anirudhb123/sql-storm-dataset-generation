SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_role,
    co.name AS company_name,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords,
    m.production_year AS release_year,
    p.info AS person_info
FROM 
    cast_info ci
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type it ON mi.info_type_id = it.id
JOIN 
    person_info p ON a.id = p.person_id
WHERE 
    m.production_year BETWEEN 2000 AND 2023
    AND c.kind LIKE '%actor%'
GROUP BY 
    a.name, t.title, c.kind, co.name, m.production_year, p.info
ORDER BY 
    release_year DESC, actor_name;
