SELECT 
    t.title AS movie_title,
    ak.name AS actor_name,
    r.role AS role_name,
    c.note AS cast_note,
    m.info AS movie_info,
    k.keyword AS movie_keyword
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cpn ON mc.company_id = cpn.id
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name ak ON c.person_id = ak.person_id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000
ORDER BY 
    t.production_year DESC, t.title;
