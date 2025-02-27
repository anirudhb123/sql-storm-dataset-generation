SELECT 
    t.title AS Movie_Title,
    a.name AS Actor_Name,
    c.kind AS Role_Kind,
    m.name AS Company_Name,
    COUNT(DISTINCT mk.keyword) AS Keyword_Count,
    GROUP_CONCAT(DISTINCT mk.keyword) AS Keywords,
    min(mi.info) AS Movie_Info
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
    company_name m ON mc.company_id = m.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year > 2000
GROUP BY 
    t.title, a.name, c.kind, m.name
ORDER BY 
    Movie_Title, Actor_Name;
