SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.person_role_id,
    CHAR_LENGTH(c.note) AS note_length,
    p.info AS person_info,
    r.role AS role_type,
    k.keyword AS movie_keyword,
    co.name AS company_name,
    m.info AS movie_info
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    person_info p ON c.person_id = p.person_id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_keyword mk ON c.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON c.movie_id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_info m ON c.movie_id = m.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
ORDER BY 
    t.production_year, a.name;
