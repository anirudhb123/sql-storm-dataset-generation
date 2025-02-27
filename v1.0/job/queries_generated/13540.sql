SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.note AS cast_note,
    ct.kind AS comp_cast_type,
    com.name AS company_name,
    mt.kind AS company_type,
    m.title AS movie_info_title,
    k.keyword AS keyword,
    p.info AS person_info,
    r.role AS role_type
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    aka_title t ON c.movie_id = t.movie_id
JOIN 
    comp_cast_type ct ON c.role_id = ct.id
JOIN 
    movie_companies mc ON c.movie_id = mc.movie_id
JOIN 
    company_name com ON mc.company_id = com.id
JOIN 
    company_type mt ON mc.company_type_id = mt.id
JOIN 
    movie_info mi ON c.movie_id = mi.movie_id
JOIN 
    title m ON c.movie_id = m.id
JOIN 
    movie_keyword mk ON c.movie_id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    role_type r ON c.role_id = r.id
ORDER BY 
    a.name, t.title;
