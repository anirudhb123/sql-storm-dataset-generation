SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    ci.nr_order AS actor_order,
    ct.kind AS character_type,
    c.name AS company_name,
    m.production_year AS release_year,
    k.keyword AS movie_keyword
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type ct ON ci.role_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info m_info ON t.id = m_info.movie_id
JOIN 
    movie_info_idx m_info_idx ON m_info.id = m_info_idx.movie_id
WHERE 
    m_info_idx.info_type_id = (SELECT id FROM info_type WHERE info = 'Genre')
ORDER BY 
    m.production_year DESC, t.title;
