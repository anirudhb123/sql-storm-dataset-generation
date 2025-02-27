SELECT 
    t.title AS movie_title, 
    p.name AS actor_name, 
    c.kind AS cast_type, 
    m.year AS production_year, 
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords 
FROM 
    title t 
JOIN 
    movie_companies mc ON t.id = mc.movie_id 
JOIN 
    company_name cn ON mc.company_id = cn.id 
JOIN 
    complete_cast cc ON t.id = cc.movie_id 
JOIN 
    cast_info ci ON cc.subject_id = ci.id 
JOIN 
    aka_name p ON ci.person_id = p.person_id 
JOIN 
    role_type r ON ci.role_id = r.id 
JOIN 
    keyword k ON t.id = k.movie_id 
LEFT JOIN 
    (SELECT movie_id, MAX(production_year) AS year FROM aka_title GROUP BY movie_id) m ON t.id = m.movie_id 
WHERE 
    cn.country_code = 'USA' 
    AND t.production_year > 2000 
GROUP BY 
    t.title, p.name, c.kind, m.year 
ORDER BY 
    t.title ASC, production_year DESC;
