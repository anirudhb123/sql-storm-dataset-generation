SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS company_type,
    tc.role AS role_type,
    COUNT(DISTINCT kw.keyword) AS keyword_count,
    AVG(m_info.info) AS average_movie_rating
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    role_type tc ON ci.role_id = tc.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
LEFT JOIN 
    movie_info m_info ON t.id = m_info.movie_id
WHERE 
    a.name IS NOT NULL AND 
    t.production_year > 2000 AND 
    ct.kind ILIKE '%production%'
GROUP BY 
    a.name, t.title, c.kind, tc.role
HAVING 
    COUNT(DISTINCT kw.keyword) > 2
ORDER BY 
    average_movie_rating DESC;
