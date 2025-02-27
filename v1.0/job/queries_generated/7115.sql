SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    c.kind AS cast_type,
    GROUP_CONCAT(DISTINCT kn.keyword ORDER BY kn.keyword SEPARATOR ', ') AS keywords,
    GROUP_CONCAT(DISTINCT cn.name ORDER BY cn.name SEPARATOR ', ') AS companies,
    YEAR(t.production_year) AS production_year
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword kn ON mk.keyword_id = kn.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name cn ON mc.company_id = cn.id
WHERE 
    a.name LIKE 'J%'
GROUP BY 
    a.id, t.id, c.id
HAVING 
    COUNT(DISTINCT kn.id) > 2
ORDER BY 
    production_year DESC, actor_name;
