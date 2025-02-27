SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    c.kind AS comp_type,
    c.name AS comp_name,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
    COUNT(DISTINCT m.id) AS complete_cast_count
FROM 
    aka_name a
JOIN 
    cast_info ci ON a.person_id = ci.person_id
JOIN 
    title t ON ci.movie_id = t.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name c ON mc.company_id = c.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast m ON t.id = m.movie_id
WHERE 
    t.production_year > 2000
GROUP BY 
    a.name, t.title, t.production_year, c.kind, c.name
HAVING 
    COUNT(DISTINCT m.id) > 5
ORDER BY 
    t.production_year DESC, actor_name;
