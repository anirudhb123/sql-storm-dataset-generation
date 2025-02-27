SELECT 
    a.name AS Actor_Name,
    t.title AS Movie_Title,
    c.kind AS Company_Kind,
    p.info AS Person_Info,
    k.keyword AS Movie_Keyword
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    company_type c ON mc.company_type_id = c.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year > 2000
    AND c.kind IS NOT NULL
    AND p.info_type_id IN (SELECT id FROM info_type WHERE info LIKE '%award%')
ORDER BY 
    Actor_Name, Movie_Title;
