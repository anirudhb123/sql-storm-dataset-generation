SELECT 
    t.title AS Movie_Title,
    a.name AS Actor_Name,
    c.kind AS Role_Type,
    cc.name AS Company_Name,
    mi.info AS Movie_Info,
    COUNT(DISTINCT mk.keyword) AS Keyword_Count
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    role_type c ON ci.role_id = c.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
    AND c.kind IN ('actor', 'actress')
GROUP BY 
    t.title, a.name, c.kind, cc.name, mi.info
ORDER BY 
    t.title, a.name;
