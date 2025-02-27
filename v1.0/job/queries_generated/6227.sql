SELECT 
    a.name AS Actor_Name,
    t.title AS Movie_Title,
    y.production_year AS Production_Year,
    c.kind AS Role_Kind,
    STRING_AGG(DISTINCT k.keyword, ', ') AS Keywords
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    role_type r ON ci.role_id = r.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    kind_type y ON t.kind_id = y.id
WHERE 
    y.kind = 'feature' AND 
    a.name IS NOT NULL
GROUP BY 
    a.name, t.title, y.production_year, c.kind
ORDER BY 
    Production_Year DESC, Actor_Name;
