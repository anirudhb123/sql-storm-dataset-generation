SELECT 
    n.name AS actor_name,
    t.title AS movie_title,
    c.nr_order AS role_order,
    ct.kind AS comp_cast_type,
    GROUP_CONCAT(DISTINCT k.keyword) AS keywords,
    GROUP_CONCAT(DISTINCT co.name) AS companies,
    MAX(m.production_year) AS max_production_year
FROM 
    aka_name an
JOIN 
    cast_info c ON an.person_id = c.person_id
JOIN 
    title t ON c.movie_id = t.id
JOIN 
    movie_keyword mk ON t.id = mk.movie_id
JOIN 
    keyword k ON mk.keyword_id = k.id
JOIN 
    complete_cast cc ON t.id = cc.movie_id
JOIN 
    movie_companies mc ON t.id = mc.movie_id
JOIN 
    company_name co ON mc.company_id = co.id
JOIN 
    comp_cast_type ct ON c.person_role_id = ct.id
JOIN 
    name n ON an.id = n.id
JOIN 
    movie_info mi ON t.id = mi.movie_id
WHERE 
    t.production_year > 2000
    AND ct.kind IN ('Actor', 'Director')
GROUP BY 
    actor_name, movie_title, role_order, comp_cast_type
ORDER BY 
    MAX(m.production_year) DESC, actor_name;
