SELECT 
    t.title AS movie_title,
    p.name AS actor_name,
    c.nr_order AS role_order,
    r.role AS role_name,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    COUNT(DISTINCT m.id) AS number_of_companies,
    MAX(mc.note) AS company_note,
    mi.info AS movie_info
FROM 
    title t
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name cn ON mc.company_id = cn.id
JOIN 
    cast_info c ON t.id = c.movie_id
JOIN 
    aka_name p ON c.person_id = p.person_id
JOIN 
    role_type r ON c.role_id = r.id
LEFT JOIN 
    movie_keyword mk ON t.id = mk.movie_id
LEFT JOIN 
    keyword k ON mk.keyword_id = k.id
LEFT JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year >= 2000 
    AND t.kind_id IN (SELECT id FROM kind_type WHERE kind = 'movie')
GROUP BY 
    t.title, p.name, c.nr_order, r.role, mi.info
ORDER BY 
    t.title, p.name, c.nr_order DESC;
