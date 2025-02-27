SELECT 
    t.title,
    a.name AS actor_name,
    c.kind AS role_type,
    y.production_year,
    k.keyword
FROM 
    title t
JOIN 
    aka_title a_t ON t.id = a_t.movie_id
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info m_i ON t.id = m_i.movie_id
JOIN 
    info_type i ON m_i.info_type_id = i.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    i.info = 'Genre'
ORDER BY 
    t.production_year DESC, actor_name;
