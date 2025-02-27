SELECT 
    t.title AS movie_title,
    a.name AS actor_name,
    c.kind AS comp_cast_type,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT m.name ORDER BY m.name) AS production_companies,
    COUNT(DISTINCT p.id) AS total_cast_members
FROM 
    title t
JOIN 
    aka_title at ON t.id = at.movie_id
JOIN 
    cast_info ci ON t.id = ci.movie_id
JOIN 
    aka_name a ON ci.person_id = a.person_id
JOIN 
    complete_cast cc ON cc.movie_id = t.id
JOIN 
    movie_companies mc ON mc.movie_id = t.id
JOIN 
    company_name m ON mc.company_id = m.id
JOIN 
    comp_cast_type c ON ci.person_role_id = c.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000
AND 
    t.kind_id in (SELECT id FROM kind_type WHERE kind = 'feature')
GROUP BY 
    t.title, a.name, c.kind
HAVING 
    COUNT(DISTINCT p.id) > 5
ORDER BY 
    t.production_year DESC, movie_title ASC;
