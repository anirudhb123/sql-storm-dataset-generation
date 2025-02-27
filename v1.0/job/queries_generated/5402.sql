SELECT 
    t.title AS movie_title,
    p.name AS actor_name,
    r.role AS role,
    c.note AS cast_note,
    m.info AS movie_info,
    k.keyword AS movie_keyword,
    cn.name AS company_name,
    ct.kind AS company_type,
    i.info AS additional_info
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info c ON cc.id = c.id
JOIN 
    aka_name p ON c.person_id = p.person_id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    person_info pi ON p.id = pi.person_id
JOIN 
    info_type i ON pi.info_type_id = i.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND r.role LIKE '%lead%'
    AND cn.country_code = 'USA'
ORDER BY 
    t.production_year ASC, 
    p.name ASC, 
    k.keyword ASC
LIMIT 100;
