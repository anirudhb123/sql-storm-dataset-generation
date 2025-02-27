
SELECT 
    a.name AS actor_name, 
    m.title AS movie_title, 
    c.kind AS company_type, 
    ti.info AS runtime_info, 
    STRING_AGG(DISTINCT k.keyword, ', ') AS keywords
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title m ON ci.movie_id = m.movie_id
JOIN 
    movie_companies mc ON m.id = mc.movie_id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_info mi ON m.id = mi.movie_id
JOIN 
    info_type ti ON mi.info_type_id = ti.id AND ti.info = 'duration'
JOIN 
    movie_keyword mk ON m.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    m.production_year >= 2000 
    AND c.kind = 'Distributor'
GROUP BY 
    a.name, m.title, c.kind, ti.info
ORDER BY 
    m.title, a.name;
