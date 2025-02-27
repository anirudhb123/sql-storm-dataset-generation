SELECT 
    t.title AS Movie_Title,
    ak.name AS Actor_Name,
    p.info AS Actor_Info,
    c.kind AS Company_Type,
    k.keyword AS Movie_Keyword
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name ak ON ci.person_id = ak.person_id
JOIN 
    person_info p ON ak.person_id = p.person_id
WHERE 
    t.production_year > 2000
ORDER BY 
    t.production_year DESC, t.title;
