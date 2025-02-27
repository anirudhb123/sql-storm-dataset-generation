SELECT 
    a.name AS actor_name,
    t.title AS movie_title,
    t.production_year,
    COUNT(DISTINCT c.person_id) AS total_cast,
    GROUP_CONCAT(DISTINCT c.nr_order || ': ' || r.role ORDER BY c.nr_order) AS cast_roles,
    GROUP_CONCAT(DISTINCT co.name ORDER BY co.name) AS company_names,
    GROUP_CONCAT(DISTINCT k.keyword ORDER BY k.keyword) AS movie_keywords
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    role_type r ON c.role_id = r.id
LEFT JOIN 
    movie_companies mc ON t.id = mc.movie_id
LEFT JOIN 
    company_name co ON mc.company_id = co.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
WHERE 
    t.production_year >= 2000 
    AND t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'feature')
GROUP BY 
    a.name, t.title, t.production_year
HAVING 
    COUNT(DISTINCT c.person_id) > 2
ORDER BY 
    t.production_year DESC, total_cast DESC;
