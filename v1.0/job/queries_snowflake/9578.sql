
SELECT 
    t.title AS movie_title,
    n.name AS actor_name,
    ARRAY_AGG(DISTINCT k.keyword) AS keywords,
    m.name AS company_name,
    r.role AS actor_role,
    ti.info AS movie_info
FROM 
    title t
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name an ON ci.person_id = an.person_id
JOIN 
    name n ON an.person_id = n.imdb_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name m ON mc.company_id = m.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id
WHERE 
    t.production_year >= 2000
AND 
    n.gender = 'F'
GROUP BY 
    t.title, n.name, m.name, r.role, ti.info
ORDER BY 
    t.title, n.name;
