SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    c.kind AS company_type,
    COUNT(DISTINCT kc.keyword) AS keyword_count,
    COUNT(DISTINCT cst.kind) AS cast_type_count,
    AVG(m.production_year) AS average_production_year
FROM 
    aka_name a
JOIN 
    cast_info c_i ON a.person_id = c_i.person_id
JOIN 
    title t ON c_i.movie_id = t.id
JOIN 
    movie_companies m_c ON t.id = m_c.movie_id
JOIN 
    company_name c ON m_c.company_id = c.id
JOIN 
    movie_keyword m_k ON t.id = m_k.movie_id
JOIN 
    keyword kc ON m_k.keyword_id = kc.id
JOIN 
    comp_cast_type cst ON c_i.person_role_id = cst.id
JOIN 
    movie_info m_i ON t.id = m_i.movie_id
WHERE 
    a.name IS NOT NULL 
    AND t.production_year > 2000 
    AND c.country_code = 'USA'
GROUP BY 
    a.name, t.title, c.kind
ORDER BY 
    average_production_year DESC, keyword_count DESC
LIMIT 100;
