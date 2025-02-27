SELECT 
    a.name AS aka_name,
    t.title AS movie_title,
    c.nr_order,
    p.info AS person_info,
    GROUP_CONCAT(k.keyword) AS keywords,
    comp.name AS company_name
FROM 
    aka_name a
JOIN 
    cast_info c ON a.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    person_info p ON a.person_id = p.person_id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name comp ON mc.company_id = comp.id
WHERE 
    t.production_year >= 2000 
    AND c.person_role_id IN (SELECT id FROM role_type WHERE role LIKE 'Actor%')
GROUP BY 
    a.name, t.title, c.nr_order, p.info, comp.name
ORDER BY 
    t.production_year DESC, a.name;
