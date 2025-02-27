SELECT 
    t.title AS Movie_Title,
    a.name AS Actor_Name,
    c.kind AS Role_Kind,
    p.info AS Person_Info,
    m.info AS Movie_Info,
    k.keyword AS Movie_Keyword,
    cn.name AS Company_Name
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type c ON ci.role_id = c.id
LEFT JOIN 
    person_info p ON a.person_id = p.person_id
LEFT JOIN 
    movie_info m ON t.id = m.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year > 2000 
    AND cn.country_code = 'USA' 
    AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'Birthdate')
ORDER BY 
    t.production_year DESC, 
    a.name ASC;
