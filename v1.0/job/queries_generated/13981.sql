-- Performance Benchmarking Query
SELECT 
    t.title AS Movie_Title,
    a.name AS Actor_Name,
    r.role AS Role,
    c.note AS Cast_Note,
    mc.note AS Company_Note,
    m.info AS Movie_Info,
    k.keyword AS Keyword
FROM 
    title t
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name a ON c.person_id = a.person_id
JOIN 
    role_type r ON c.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    movie_info m ON t.id = m.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
ORDER BY 
    t.production_year DESC, a.name;
