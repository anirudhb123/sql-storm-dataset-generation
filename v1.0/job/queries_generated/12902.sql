SELECT 
    t.title,
    a.name AS actor_name,
    c.kind AS company_type,
    m.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    title t
JOIN 
    aka_title a_t ON t.id = a_t.movie_id
JOIN 
    cast_info c_i ON t.id = c_i.movie_id
JOIN 
    aka_name a ON a.id = c_i.person_id
JOIN 
    movie_companies m_c ON t.id = m_c.movie_id
JOIN 
    company_type c ON c.id = m_c.company_type_id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON k.id = mk.keyword_id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, a.name;
