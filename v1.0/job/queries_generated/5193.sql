SELECT 
    a.name AS Actor_Name,
    t.title AS Movie_Title,
    c.kind AS Role_Kind,
    co.name AS Company_Name,
    k.keyword AS Movie_Keyword,
    m.info AS Movie_Info
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    aka_title t ON ci.movie_id = t.movie_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_info m ON t.id = m.movie_id
WHERE 
    a.name LIKE 'J%'
    AND t.production_year > 2000
    AND co.country_code = 'USA'
ORDER BY 
    t.production_year DESC, a.name ASC;
