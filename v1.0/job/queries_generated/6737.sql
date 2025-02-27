SELECT 
    t.title, 
    a.name AS actor_name, 
    c.kind AS company_type,
    GROUP_CONCAT(DISTINCT kw.keyword) AS keywords,
    COUNT(DISTINCT ci.id) AS total_cast 
FROM 
    aka_title at
JOIN 
    title t ON at.movie_id = t.id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_type ct ON mc.company_type_id = ct.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    t.production_year BETWEEN 2000 AND 2020
GROUP BY 
    t.title, a.name, c.kind 
HAVING 
    total_cast > 5
ORDER BY 
    t.production_year DESC, total_cast DESC;
