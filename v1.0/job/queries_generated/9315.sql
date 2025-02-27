SELECT 
    t.title AS Movie_Title,
    a.name AS Actor_Name,
    r.role AS Actor_Role,
    c.kind AS Company_Kind,
    mi.info AS Movie_Info,
    kw.keyword AS Movie_Keyword
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    t.production_year >= 2000
    AND c.country_code = 'USA'
    AND mi.info_type_id IN (
        SELECT id FROM info_type WHERE info IN ('Box Office', 'Awards')
    )
ORDER BY 
    t.production_year DESC, 
    a.name ASC, 
    kw.keyword ASC;
