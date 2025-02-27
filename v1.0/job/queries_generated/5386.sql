SELECT 
    ak.name AS aka_name,
    t.title AS movie_title,
    p.gender AS actor_gender,
    c.kind AS company_type,
    k.keyword AS movie_keyword,
    ci.note AS cast_note,
    cc.status_id AS cast_status
FROM 
    aka_name ak
JOIN 
    cast_info ci ON ak.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    person_info p ON ak.person_id = p.person_id
JOIN 
    comp_cast_type cct ON ci.person_role_id = cct.id
WHERE 
    t.production_year BETWEEN 2000 AND 2023
    AND p.info_type_id = (SELECT id FROM info_type WHERE info = 'birth_date')
    AND k.keyword LIKE 'Action%'
ORDER BY 
    t.production_year DESC, ak.name;
