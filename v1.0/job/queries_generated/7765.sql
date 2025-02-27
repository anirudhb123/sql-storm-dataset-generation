SELECT 
    a.name AS actor_name, 
    t.title AS movie_title, 
    y.production_year, 
    c.kind AS company_type,
    GROUP_CONCAT(DISTINCT kw.keyword) AS keywords
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
    company_type ct ON mc.company_type_id = ct.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kw ON mk.keyword_id = kw.id
WHERE 
    a.name IS NOT NULL AND 
    t.production_year >= 2000
GROUP BY 
    a.name, t.title, y.production_year, c.kind
ORDER BY 
    production_year DESC, actor_name ASC;
