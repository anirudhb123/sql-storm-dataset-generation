SELECT 
    t.title, 
    p.name AS person_name, 
    c.kind AS role_type,
    m.name AS company_name,
    k.keyword AS movie_keyword,
    m_info.info AS movie_info
FROM 
    title AS t
JOIN 
    cast_info AS ci ON t.id = ci.movie_id
JOIN 
    aka_name AS p ON ci.person_id = p.person_id
JOIN 
    role_type AS c ON ci.role_id = c.id
JOIN 
    movie_companies AS mc ON t.id = mc.movie_id
JOIN 
    company_name AS m ON mc.company_id = m.id
JOIN 
    movie_keyword AS mk ON t.id = mk.movie_id
JOIN 
    keyword AS k ON mk.keyword_id = k.id
JOIN 
    movie_info AS m_info ON t.id = m_info.movie_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, 
    p.name, 
    k.keyword;
