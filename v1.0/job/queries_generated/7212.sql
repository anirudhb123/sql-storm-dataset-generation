SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS cast_type,
    co.name AS company_name,
    GROUP_CONCAT(kw.keyword) AS keywords,
    COUNT(mo.id) AS total_movies
FROM 
    title t
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    cast_info ci ON cc.subject_id = ci.id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
JOIN 
    aka_title at ON at.id = t.id
WHERE 
    t.production_year >= 2000
GROUP BY 
    t.title, a.name, c.kind, co.name
ORDER BY 
    total_movies DESC
LIMIT 10;
