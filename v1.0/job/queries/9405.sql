SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.note AS role_note,
    p.info AS person_info,
    k.keyword AS movie_keyword,
    m.name AS company_name,
    d.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_info m_info ON t.id = m_info.movie_id
JOIN 
    movie_info d ON m_info.info_type_id = d.info_type_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name m ON mc.company_id = m.id
JOIN 
    person_info p ON a.person_id = p.person_id 
WHERE 
    t.production_year >= 2000 
    AND m.country_code = 'USA' 
    AND k.keyword ILIKE '%action%'
ORDER BY 
    t.production_year DESC, a.name;
