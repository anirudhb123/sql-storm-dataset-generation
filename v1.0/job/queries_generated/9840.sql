SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS cast_role,
    m.name AS company_name,
    m_info.info AS movie_info,
    k.keyword AS keyword 
FROM 
    title t 
JOIN 
    complete_cast cc ON t.id = cc.movie_id 
JOIN 
    cast_info ci ON cc.subject_id = ci.id 
JOIN 
    aka_name a ON ci.person_id = a.person_id 
JOIN 
    role_type c ON ci.role_id = c.id 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name m ON mc.company_id = m.id 
LEFT JOIN 
    movie_info m_info ON t.id = m_info.movie_id 
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id 
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id 
WHERE 
    t.production_year BETWEEN 2000 AND 2020 
    AND a.name IS NOT NULL 
    AND k.keyword IS NOT NULL 
ORDER BY 
    t.title, a.name;
