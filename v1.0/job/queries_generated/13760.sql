SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS role_type,
    m.production_year,
    k.keyword AS movie_keyword,
    i.info AS additional_info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info m_info ON t.id = m_info.movie_id
JOIN 
    info_type i_type ON m_info.info_type_id = i_type.id
WHERE 
    a.name IS NOT NULL
ORDER BY 
    m.production_year DESC, a.name;
